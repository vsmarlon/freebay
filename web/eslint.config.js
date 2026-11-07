import eslint from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';

// Policy (AGENTS.md): icons are inline SVG/images — third-party icon packages are banned
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

const useEffectMessages = [
  { selector: 'CallExpression[callee.name="useEffect"]', message: 'useEffect is banned: derive state during render, handle events in handlers, or describe subscriptions with a framework primitive (see AGENTS.md).' },
  { selector: 'CallExpression[callee.property.name="useEffect"]', message: 'useEffect is banned: derive state during render, handle events in handlers, or describe subscriptions with a framework primitive (see AGENTS.md).' },
];

// Grandfathered files that still contain useEffect (legacy migration debt).
// Delete an entry when the file is migrated. NEVER add files here; policy is error-level everywhere else.
const legacyEffectFiles = [];
export default [
  { ignores: ['build/**', '.react-router/**', 'node_modules/**'] },
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  { files: ['**/*.{js,mjs,ts,tsx}'], languageOptions: { globals: { ...globals.browser, ...globals.node }, parserOptions: { ecmaFeatures: { jsx: true } } } },
  {
    files: ['app/**/*.{ts,tsx}', 'tests/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': ['error', ...bannedIconImports],
      'no-restricted-syntax': ['error', ...useEffectMessages],
    },
  },
  ...(legacyEffectFiles.length ? [{ files: legacyEffectFiles, rules: { 'no-restricted-syntax': 'off' } }] : []),
];
