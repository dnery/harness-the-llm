[$implement](/Users/danilo.nery/.agents/skills/implement/SKILL.md) {clipboard}:
- As much as possible, try to minimize code additions;
- *We love code deletions* - opportunistic refactors that reduce LoC are encouraged when they also improve human maintainability.
- Once you're sufficiently confident, [$sfr3-ship](/Users/danilo.nery/.agents/skills/sfr3-ship/SKILL.md) it until you reach a stabilized PR;
- Be principled when following up on bugbot and codex-connector comments: only make changes if the comment surfaces a real production gap without misunderstanding intent; otherwise, dismiss it with an acknowledgement;
- Monitor the subagent created by the [$sfr3-ship](/Users/danilo.nery/.agents/skills/sfr3-ship/SKILL.md) skill to ensure that the above guideline is respected: prevent potentially overzealous bugbot/codex-connector comments from steering efforts towards intent misalignment or code sprawl; intervene if necessary;

Once the PR is stabilized and you're waiting, follow this protocol:
- HitL: Nudge me towards manual review and merge or requesting a follow up, and wait for my reply;
- Once I confirm that I've merged the changes, immediately proceed to deploy the latest `main` using guidance from [$sfr3-deployment](/Users/danilo.nery/.agents/skills/sfr3-deployment/SKILL.md), while progressively validating your work;
- After deployment lands, do the sufficient post-deployment verification to unblock the follow-up backfill/live repair work;
- HitL: Nudge me towards doing the backfill work in another thread, with a paste-ready prompt referencing this thread;
- Once I confirm that the live repair work is completed, do all post-deploy verification was previously skipped.
- If verification cannot be completed within 1 hour of runtime since our last interaction then:
  1. Capture and show what *was* verified thus far,
  2. Create one or more timers to regularly monitor the relevant prod chatter and complete the verifications,
  3. Provide a good-enough final response confirming what was verified, what was not but is likely to be captured in scheduled runs, and what cannot be feasibly verified.

Notes:
- If you choose to eat some tech debt and dismiss a bugbot/codex-connector comment, judge whether there's value in creating a tricket to follow up on it later;
- If you decide that a ticket is applicable, then:
  - Choose the most adequate project between the ones assigned to me (likely https://linear.app/sfr3/project/leasing-0-errors-9581744a743e/issues);
  - Verify tracking: if the issue is already tracked by another ticket, verify that it encompasses the issue in it's latest form and correct it if needed, otherwise create a new ticket;
  - Verify milestone: if there already is an adequate milestone, add it to the existing milestone, otherwise create a new one and put the ticket there;
  - Verify assignment: ensure ticket, milestone and project are assigned to me (if not already assigned to someone else);
  - Verify status: update the status if needed based on your judgment; only set to urgent if the issue concerns a prod outage;
- If another ongoing thread is doing work that concerns your own and there is some risk of race, duplicate/fragmented work, 'alien crosstalk' or significant disruption, cooperate with it:
  - Actively monitor it and other running threads to ensure harmonious concurrency;
  - Intervening with direct messages is allowed but only do it if strictly necessary;
- Codex-connector comments usually land minutes later than bugbot comments and don't have a clear 'in-progress/done' signal; wait for slightly longer on each PR watch iteration to ensure you always catch them.
- Keep the associated Linear tracking status(es) up-to-date with latest reality of the effort at every opportunity;
  - Be very sparing with free-form text updates, and when do decide to post them, be concise and clear with the contents;
- At any turn, if a slack update is warranted, don't post anything directly, instead give me a draft the thread/channel link in which to post it in;
  - Support channel audience is strictly non-technical, so completely forego technical jargon, architectural reference or mentions to local assets;
  - As a frame of reference, consider this: if a code issue is concerned, we shouldn't go much deeper than "X happened because of a code issue".
- Capture my attention in HitL (Human-in-the-loop) points:
  - Besides your in-thread response, push MacOS notification (osascript);
  - If I do not reply within 1 minute, also push a `ntfy` message on the `chopper` topic;
- Structure your responses using guidance from [$i-have-adhd:i-have-adhd](/Users/danilo.nery/.codex/plugins/cache/i-have-adhd/i-have-adhd/0.1.0/skills/i-have-adhd/SKILL.md).
