# Model catalog (Jul–Sep 2026)

Living taxonomy for hosted / API / local runtimes.
Tracked: Linear SVE-6, GitHub kuuratsanik/civic-infrastructure#4.

## Isolation gate

This file is **public catalog only**.

Do not put in this file:
- civic-lane webhook URLs, bus tokens, fleet.json, services.json
- Gmail / Outlook / Linear / GitHub / Notion / Drive IDs used by Comms Bus
- API keys, OAuth tokens, device paths, config.json
- Fiction project paths (ASG / SFR / Unrouted bodies)

Pipeline (docs only):

```
Linear SVE-6 / GitHub #4
        → docs/uncensored-ai-catalog-2026-09.md
        → optional Notion appendix (no secrets)
        → optional mail to sven.katkosilt@gmail.com (draft unless SEND)
```

## 1. Hosted platforms (low-moderation / high-limit)

| Name | Notes |
|---|---|
| Venice.ai | Zero-data-retention options, adjustable filter, 200+ models |
| NoLimitGPT (nolimitgpt.net) | Low-refusal on legal prompts; subscription high-context |
| Featherless.ai | Hosted modified open weights (Qwen, Gemma, Mistral, Llama); flat-rate |
| HackAIGC | Text / image / video; minimal gating; flat monthly |
| EvilGPT / unrestricted.chat / NoFilterGPT | Consumer UIs, relaxed refusals |
| CrushOn, SpicyChat, Candy AI, OurDream | Persona / character UIs |

Hosted still blocks illegal content. “Unlimited” usually means a paid core tier, not every frontier model.

## 2. Developer endpoints (OpenAI-compatible)

- abliteration.ai
- unfil.ai
- audn.ai
- Featherless API

Drop-in REST for agent pipelines that want a lower refusal baseline. Metered token pools or seat tiers. No keys in this repo.

## 3. Local / sovereign runtimes

Runtimes: Ollama, Open WebUI, LM Studio, Atomic Chat, llama.cpp, SillyTavern.

Weight families (examples, not an install list): abliterated / de-restricted Qwen, Gemma, Mistral, Llama, DeepSeek, Dolphin, Heretic.

Boundary: data stays on the box; hardware-limited; no provider filter.

## 4. Infra hops (pointers only)

- GitHub: this file + issue #4
- Linear: SVE-6 on project Comms Bus
- Mail: Outlook failover already used 2026-09-07; Gmail connector may need re-auth
- Push: no ntfy/Pushover yet; GitHub/Linear clients only unless you add a generic webhook

## 5. What this file is not

Not a Comms Bus config. Not a ceremony. Not a deploy. Not a resume of AI services automation `db368212`.
