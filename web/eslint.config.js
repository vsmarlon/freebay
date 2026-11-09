import eslint from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';
import reactHooks from 'eslint-plugin-react-hooks';
import betterTailwind from 'eslint-plugin-better-tailwindcss';

// Policy: icons are inline SVG/images — third-party icon packages are banned
// (lucide-react, react-icons, heroicons, phosphor, feather; build your own <svg> strokes).
const bannedIconImports = [{
  patterns: [
    'lucide-react',
    'react-feather',
    '@heroicons/*',
    '@phosphor-icons/*',
    'react-icons/*',
  ],
}];

// Effects policy (AGENTS.md): no useEffect outside a named custom hook. These files still
// carry the pre-policy pattern; delete an entry as its file migrates. Hooks that subscribe
// to an external system (use-chat-socket, use-audio-recorder, use-debounced-value,
// location-picker) are listed only until they move under a hooks/ folder with the guard.
const legacyEffectFiles = [
  'app/components/location-picker.tsx',
  'app/core/use-debounced-value.ts',
  'app/features/account/close-friends.tsx',
  'app/features/account/connections.tsx',
  'app/features/account/notifications.tsx',
  'app/features/account/safety-list.tsx',
  'app/features/auth/step-up-dialog.tsx',
  'app/features/chat/hooks/use-audio-recorder.ts',
  'app/features/chat/hooks/use-chat-socket.ts',
  'app/features/chat/media.tsx',
  'app/features/chat/thread.tsx',
  'app/features/commerce/checkout.tsx',
  'app/features/marketplace/buy.tsx',
  'app/features/social/post-media.tsx',
  'app/features/stories/archive.tsx',
  'app/features/stories/player.tsx',
];

export default [
  { ignores: ['build/**', '.react-router/**', 'node_modules/**'] },
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  { files: ['**/*.{js,mjs,ts,tsx}'], languageOptions: { globals: { ...globals.browser, ...globals.node }, parserOptions: { ecmaFeatures: { jsx: true } } } },
  {
    files: ['**/*.{js,mjs,ts,tsx}'],
    plugins: { 'react-hooks': reactHooks },
    rules: {
      // Official hooks correctness contract (rules-of-hooks error, exhaustive-deps warn is
      // promoted to error below) — see reactHooks.configs['recommended-latest'].
      ...reactHooks.configs['recommended-latest'].rules,
      // exhaustive-deps is the enforcement for the useEffect policy in AGENTS.md:
      // effects are allowed for external systems ONLY when their dependencies are honest.
      'react-hooks/exhaustive-deps': 'error',
    },
  },
  {
    files: ['app/**/*.{ts,tsx}', 'tests/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': ['error', ...bannedIconImports],
    },
  },
  {
    files: ['app/**/*.{ts,tsx}'],
    rules: {
      // Layout is Prettier's job; these two keep the dense one-liner style from returning.
      'max-statements-per-line': ['error', { max: 1 }],
      'max-len': ['error', {
        code: 120,
        ignoreUrls: true,
        ignoreStrings: true,
        ignoreTemplateLiterals: true,
        ignoreRegExpLiterals: true,
        ignoreComments: true,
      }],
    },
  },
  {
    files: ['app/**/*.{ts,tsx}'],
    ignores: legacyEffectFiles,
    rules: {
      'no-restricted-syntax': ['error',
        { selector: "CallExpression[callee.name='useEffect']", message: 'Use a custom hook, a callback ref, useSyncExternalStore or a query. See web playbook section 4.' },
        { selector: "CallExpression[callee.property.name='useEffect']", message: 'Same as above.' },
      ],
    },
  },
  {
    files: ['app/**/*.{ts,tsx}'],
    plugins: betterTailwind.configs.recommended.plugins,
    settings: { 'better-tailwindcss': { entryPoint: 'app/styles.css' } },
    rules: {
      ...betterTailwind.configs.recommended.rules,
      // Tailwind 4 component classes (ui-button, surface, icon-control, …) live in styles.css
      // per AGENTS.md; with this on, no-unknown-classes reads them as registered and still
      // flags classes that exist nowhere.
      'better-tailwindcss/no-unknown-classes': ['error', { detectComponentClasses: true, ignore: [
        // style enums for story text overlays (never used as css class names)
        '^(classic|strong|editorial|compact)$',
      ] }],
      // ponytail: formatting rules (class order/line wrapping/whitespace) stay off until the
      // correctness batch is green; enabling them later is a mechanical autofix batch.
      'better-tailwindcss/enforce-consistent-class-order': 'off',
      'better-tailwindcss/enforce-consistent-line-wrapping': 'off',
      'better-tailwindcss/no-unnecessary-whitespace': 'off',
    },
  },
];
