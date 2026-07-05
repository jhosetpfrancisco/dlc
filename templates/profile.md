# DLC profile — personal defaults
<!-- Lives at ~/.claude/dlc/profile.md on YOUR machine. Never inside any repo,   -->
<!-- and never inside the public engine. Layer 2 of the cascade:                 -->
<!--     engine defaults  <  this profile  <  workspace policies                 -->

## Identity
- **Default commit identity:** Jane Doe <jane@example.com>

## Language
- **Conversation / reports:** en
  <!-- the engine never dictates conversation language; your CLAUDE.md and this profile do -->

## Overrides of engine defaults
- allow_ai_coauthor: false        <!-- engine default; set true only if you WANT AI-attributed commits -->
- default_branch_policy: main

## Global preferences the planner should respect
- <e.g. "KISS over cleverness", "prefer boring technology", "strict TypeScript everywhere">
