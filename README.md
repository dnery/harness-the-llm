# Gemini 3 Pro System Prompts

Three specialized agent personas designed for Google AI Studio, following Gemini 3 Pro's recommended hybrid XML format and prompting best practices.

## Quick Start

1. Open [Google AI Studio](https://aistudio.google.com/)
2. Create a new prompt or chat
3. Click "System Instructions"
4. Copy everything **below the horizontal rule** (`---`) from your chosen prompt file
5. Paste into the System Instructions field

## The Three Agents

### 1. The Seasoned Associate Software Architect
**File:** `01-software-architect.md`

**Best for:**
- Designing new systems from scratch
- Analyzing and evolving legacy systems
- Writing ADRs, technical specifications, and system documentation
- Critical review of architectural proposals
- Reliability/scalability/maintainability assessments

**Personality:** Methodical, skeptical, articulate. The senior engineer who's seen patterns succeed and fail across multiple companies. Will push back on hand-wavy proposals and demand concrete trade-off analysis.

**Example use cases:**
- "Design a notification system for 10M users"
- "Review this microservices architecture proposal"
- "Write an ADR for our authentication strategy"
- "What are the failure modes in this design?"

---

### 2. The Energetic and Resourceful Engineer  
**File:** `02-resourceful-engineer.md`

**Best for:**
- Implementing features from specifications
- Test-driven development
- Finding workarounds for blockers
- Writing production-quality code with tests
- Breaking down large tasks into deliverables

**Personality:** High-energy, pragmatic, test-obsessed. The teammate who ships quality code on time and refuses to be blocked. Treats unavailable dependencies as invitations to mock and move forward.

**Example use cases:**
- "Implement this user authentication flow"
- "Write tests for this payment service"
- "The external API isn't ready—how do I unblock?"
- "Help me break this epic into testable increments"

---

### 3. The Prompter (Gandalf to the Palantír)
**File:** `03-the-prompter.md`

**Best for:**
- Turning vague ideas into effective Gemini 3 Pro prompts
- Debugging prompts that aren't working
- Learning prompt engineering principles
- Creating reusable prompt templates

**Personality:** Warm, knowledgeable guide. Translates fuzzy human intent into precise model instructions. Teaches *why* prompts work, not just *what* to write.

**Example use cases:**
- "I want to analyze customer feedback but don't know how to ask"
- "This prompt keeps giving me garbage—fix it"
- "Create a prompt for code review"
- "Teach me how to structure prompts for complex tasks"

---

## Design Principles

These prompts follow Gemini 3 Pro's documented best practices:

| Principle | Implementation |
|-----------|----------------|
| **Directness over persuasion** | No fluff or politeness padding; clear instructions |
| **Consistent XML structure** | All prompts use `<tag>` format, never mixed with Markdown headers in structure |
| **Explicit constraints** | Hard rules stated clearly, not implied |
| **Planning triggers** | Complex tasks include self-reflection and planning steps |
| **Output format specification** | Each prompt defines expected response structure |
| **Error handling** | Guidance for missing information or ambiguous requests |

## Customization Tips

**To adjust verbosity:**
Find the `<format_defaults>` section and modify:
```xml
- Verbosity: Low  <!-- Options: Low / Medium / Medium-High / High -->
```

**To change tone:**
Modify the `<role>` section's personality traits or the `<communication_style>` section.

**To add domain expertise:**
Add a `<domain_knowledge>` section with relevant context, terminology, or constraints.

**To add few-shot examples:**
Add more examples to the `<few_shot_examples>` section following the existing pattern.

## Usage Notes

- **Context window**: These prompts are ~2-3k tokens each. Gemini 3 Pro handles this easily, but be mindful when adding large documents.

- **Combining with user input**: The `<context>` and `<task>` tags in the user message provide the "Palantír view"—what the agent should focus on.

- **Iteration**: These are starting points. Refine based on your specific use cases. The Prompter can help you adapt the other two prompts!

## Example Workflow

**Using The Architect → The Engineer pipeline:**

1. **Start with Architect**: "Design a caching layer for our API that handles 100k requests/minute"
2. Architect produces: System design, ADR, component breakdown, interface definitions
3. **Switch to Engineer**: "Implement the cache invalidation service from the design above"
4. Engineer produces: Test-first implementation, mock services, PR-ready code

**Using The Prompter to create new agents:**

1. **Tell Prompter**: "I need an agent that reviews legal contracts for risky clauses"
2. Prompter produces: Complete system prompt in hybrid XML format
3. **Use the new prompt**: Paste into a new AI Studio session

---

## References

- [Gemini API Prompting Strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies)
- [Gemini 3 Pro Prompt Practices](https://www.philschmid.de/gemini-3-prompt-practices) (Phil Schmid)
- [Building Agents with Gemini 3](https://www.philschmid.de/building-agents) (Phil Schmid)

---

*Created for Danilo by Claude Opus 4.5 • December 2025*
