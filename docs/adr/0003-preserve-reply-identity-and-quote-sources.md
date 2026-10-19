# Preserve reply identity and reference quote sources

Status: accepted design; implementation pending. Date: 2026-10-13.

X-inspired conversations will retain FreeBay's existing comment identities and parent relationships, as required by the owner's compatibility approval. Quote posts are distinct publications with their own conversations and references to eligible original posts or replies. Converting historical comments into posts would reuse some post actions, but would also require identity compatibility and changes to moderation, counts, mentions, notifications, and existing clients; targeted reply actions and quote relations are the smaller change.

Embed rendering must recheck source eligibility rather than make a copied source body authoritative after deletion or access loss. Reposts and quotes preserve current private-content restrictions. The exact API and Prisma additions belong to the implementation plan; approval covers source/model changes and guarded test verification, while production migrations remain owner-run.

Owner decisions and feature boundaries: [conversation design](../COMMENTS_UX_DESIGN.md).
