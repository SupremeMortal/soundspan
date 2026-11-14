# Client surface operations

One module per client-surface tag (`session.ts`, `library.ts`, ...), each
exporting an array of operations built with `defineOperation`. `../clientSurface.ts`
concatenates the arrays into `clientSurfaceOperations`.
