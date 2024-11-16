local ls = require 'luasnip'
local snippet = ls.snippet
local insertNode = ls.insert_node
local textNode = ls.text_node

ls.add_snippets('twig', {
  snippet('p', {
    textNode "{{ include('partials/",
    insertNode(1),
    textNode { "' }}" },
  }),

  snippet('pp', {
    textNode "{{ include('partials/",
    insertNode(1),
    textNode { "', {", '' },
    insertNode(0),
    textNode { '', '}) }}' },
  }),

  snippet('c=', {
    textNode 'class="',
    insertNode(1),
    textNode { '"' },
  }),
})
