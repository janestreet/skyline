# Bonsai\_web\_ui\_tree\_table


`bonsai_web_contrib_tree_table` is a library for "tree-style tables", which are tables containing
rows that have parents.  These differ from normal tables in a few ways:

1. Rows need to know how many ancestors they have in order to render with indentation.
2. Sorting needs to prioritize ancestors so that a child is never above or outside of
   its direct parent.
