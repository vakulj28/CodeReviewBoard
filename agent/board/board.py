"""
The supervisor (the "chair") that runs the whole panel, plus run_board().

Flow:
  1. The supervisor agent is given the four critics AS TOOLS. Handed a diff, it
     calls each critic and aggregates their findings into one text review.
     (This is the agentic part: the model decides to call the tools.)
  2. A second, tool-less 'formatter' agent turns that text into our strict Review
     schema, so the result is clean JSON the rest of the system can rely on.
"""

from strands import Agent

from board.critics import (
    performance_critic,
    security_critic,
    style_critic,
    tests_critic,
)
from board.model import make_model
from board.schema import Review

SUPERVISOR_PROMPT = (
    "You are the chair of a code review board. You have four specialist critics "
    "available as tools: security, performance, style, and tests. For the code diff "
    "you are given, consult ALL FOUR critics by calling each tool once with the diff. "
    "Then write one consolidated review listing every issue they found, grouped by "
    "dimension, each with its severity. Be concise."
)

FORMATTER_PROMPT = (
    "You convert a consolidated code review into structured data. Pull out each distinct "
    "issue as a finding: its dimension (security/performance/style/tests), severity "
    "(high/medium/low), a one-sentence issue, and a one-sentence suggestion. Add a short "
    "overall summary. If there are no issues, return an empty findings list."
)


def run_board(diff: str) -> Review:
    # 1) The chair consults the panel. Passing the critics as `tools` is what lets
    #    the supervisor call them. It returns a free-text consolidated review.
    supervisor = Agent(
        model=make_model(),
        system_prompt=SUPERVISOR_PROMPT,
        tools=[security_critic, performance_critic, style_critic, tests_critic],
        callback_handler=None,
    )
    consolidated = str(supervisor(f"Review the following code diff:\n\n{diff}"))

    # 2) A tool-less formatter turns that text into our strict Review schema.
    formatter = Agent(
        model=make_model(),
        system_prompt=FORMATTER_PROMPT,
        callback_handler=None,
    )
    result = formatter(
        f"Convert this code review into the structured schema:\n\n{consolidated}",
        structured_output_model=Review,
    )
    return result.structured_output


if __name__ == "__main__":
    # A tiny demo diff with a planted issue in several dimensions.
    sample_diff = """\
+++ b/handler.py
@@
+def get_user(request):
+    uid = request.args.get("id")
+    rows = db.execute("SELECT * FROM users WHERE id = " + uid)   # SQL built by string concat
+    results = []
+    for r in rows:
+        results.append(db.execute("SELECT * FROM orders WHERE user = " + str(r.id)))  # query in a loop
+    return eval(request.args.get("fmt"))(results)                # eval on user input
"""
    review = run_board(sample_diff)

    print("\n=== Board verdict ===")
    print("Summary:", review.summary)
    for f in review.findings:
        print(f"- [{f.severity}] ({f.dimension}) {f.issue}  -> {f.suggestion}")