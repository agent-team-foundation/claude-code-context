---
title: "About This Tree"
owners: []
soft_links: [/reconstruction-guardrails]
---

# About This Tree

This repository exists to answer one question: what knowledge would another team need in order to rebuild a Claude Code equivalent from scratch without copying Claude Code source?

The answer is not "all files" or "all strings." It is the durable knowledge that shapes the system:

- what user-facing capabilities exist
- which subsystems must cooperate to deliver them
- where the important state boundaries and failure modes live
- what product and safety constraints cut across domains

This tree is therefore a clean-room reconstruction spec. It captures the minimum durable knowledge required to make correct design decisions, while excluding original source expression, repo-local implementation detail, and tooling noise that would turn the tree into a source mirror.
