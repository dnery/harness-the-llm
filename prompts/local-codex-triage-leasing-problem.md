Investigate the problems reported in {clipboard}.

- Assert whether the snapshot script correctly classifies the associated records;
  - If you find misclassification issues in the script, fix them and verify as you proceed;
- Assert whether the problems surface code issues;
  - If so, ensure each issue is tracked in [https://linear.app/sfr3/project/leasing-0-errors-9581744a743e/activity](https://linear.app/sfr3/project/leasing-0-errors-9581744a743e/activity):
    - If the issue is already tracked by another ticket, verify that it covers the issue in it's latest form and correct it if needed, otherwise create a new ticket;
    - If there already is an adequate milestone, add it to the existing milestone, otherwise leave the milestone unset;
    - Ensure ticket and milestone are assigned to me (if not already assigned to someone else);
    - Update the status if needed based on your judgment; only set to urgent if the issue concerns an open prod outage;
- If the problems clearly point to an open prod outage, track both problem and resolution path according to the guidance above;
- If there's no outage and live repair of associated records is applicable, then:
  - Do live repair of the records associated with the problems reported;
  - Reference resolutions in other signing-platform project threads if you need a starting point;
  - If the repair is not well known yet, record the summarized strategy for this category of error in the snapshot script;
- Structure your response based on [$i-have-adhd:i-have-adhd](/Users/danilo.nery/.codex/plugins/cache/i-have-adhd/i-have-adhd/0.1.0/skills/i-have-adhd/SKILL.md) guidance and include, regardless of decisions made:
  - What you did;
  - Tabulated results of a full snapshot script run;
  - Advice on what to do next based on your assessment and issue blast radius.
Do a full snapshot script run and show me the tabulated results along with your assessment and a report of what you did (regardless of choices made);

Notes:
- All prod readonly tools and skills are allowed;
  - Prefer [@Chromium](plugin://computer-use@openai-bundled?app=org.chromium.Chromium) for things that need to be validated visually;
    - If visual verification is needed in MIP (move-in portal) or Renewal portal and it is not authenticated, authenticate like this:
      - 1) Open the move-in or portal prod test record (listed in "Resources", choose based on context) and request the TOTP,
      - 2) Retrieve TOTP from the message sent in #2fa channel in [@slack](plugin://slack@openai-curated-remote),
      - 3) Log into the portal using retrieved TOTP,
      - 4) Re-navigate to the record you were trying to debug originally;
    - The above process relies on auth cookies being preserved to work; you're allowed to find workarounds and alternatives based on the specific situation presented;
  - If some auth is required that is not available in your environment but available in 1password, you may fetch with an explicit notice of what you're fetching;
- Prod mutations are allowed strictly to the point that they're required to repair lease records associated with the reported problems;
  - Be careful when doing prod mutations outside of the beaten path: do not lot eagerness to solve the issue lead you to cause business disruption or a prod outage;
- If another ongoing thread is doing work that concerns your own and there is risk of data race, duplicate/fragmented work, alien crosstalk or otherwise significant disruption, cooperate with it:
  - Actively monitor it and other running threads to ensure harmonious concurrency;
  - Intervening is allowed but only do it if strictly necessary;
- If a slack update is warranted, don't post anything on slack directly, instead give me a draft in your response alongside the thread/channel link in which to post it in;
  - Support channel audience is strictly non-technical, so completely exclude technical jargon, architectural reference, local asset mentions;
  - As a point of reference, consider this: if a code issue is concerned, we shouldn't go deeper than "X happened because of a code issue".
- If you decide to write something out on Linear, consider the copy readability by human stakeholders and the potential cognitive overhead.


Resources:
- Move-in portal prod test record: https://www.americanave.com/move-in/a0T3x00000dv7cqEAA
- Renewal portal prod test record: https://www.americanave.com/renewal/a0S3x00000dO2E6EAK
