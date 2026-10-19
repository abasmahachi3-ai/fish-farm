# Catfish Farm maintenance

- The production host is GitHub Pages for `abasmahachi3-ai/fish-farm`, branch `main`, root directory. Preserve this hosting and the existing Supabase integration.
- Read the current code and branch head before changing anything. Never overwrite concurrent changes or force-push.
- Preserve existing production data and configuration storage keys (`catfish_v2_config`, `catfish_v2_farm`, `catfish_v2_batch`). Do not commit credentials or database exports.
- Do not execute SQL, migrations, destructive operations, RLS changes, or test writes against production without first inspecting the proposed impact and obtaining explicit user approval. The original `supabase.sql` is not an upgrade script.
- Validate frontend changes with `node --test tests/regression.cjs`. Tests must use mocks, never production data.
- Push authorized changes directly through GitHub; users should not have to upload files manually. Confirm Pages deployment for the pushed commit and disclose any verification limitations.
