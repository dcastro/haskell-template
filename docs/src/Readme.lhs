\begin{code}%hidden
{-# LANGUAGE GHC2024 #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedStrings #-}

module Readme where

-- imports needed for the "utils" at the bottom.
import Effectful.SQLite.Simple (FromRow(..))

\end{code}


sqlite-simple-effectful
===

Adaptation of the [sqlite-simple](https://hackage.haskell.org/package/sqlite-simple) library for the [effectful](https://hackage.haskell.org/package/effectful) ecosystem.


Getting started
---

This package provides a dynamic `SQLite` effect that can be used to run SQLite queries in an effectful context.

Use `useConnection` to obtain a connection to the database and run queries.

\begin{code}
import Effectful.SQLite.Simple (SQLite)
import Effectful.SQLite.Simple qualified as SQL

import Effectful
import Effectful.Concurrent (runConcurrent)
import Data.Function ((&))
import Control.Concurrent.MVar qualified as MVar

app :: (SQLite :> es) => Eff es [User]
app = do
  SQL.useConnection \conn -> do
    SQL.query_ conn "SELECT * FROM users"
\end{code}


The effect can be interpreted with `runSQLiteUnsync`, suitable for single-threaded applications,
or `runSQLiteSync`, which is safe to use in multi-threaded applications.

\begin{code}
main :: IO [User]
main =
  SQL.withConnection "users.db" \conn -> do
    connVar <- MVar.newMVar conn
    app
      & SQL.runSQLiteSync connVar
      & runConcurrent
      & runEff
\end{code}


Pooled connections
---

@include:Readme/Pooled.lhs@



Using multiple connections
---

The package also provides ["labeled effects"][labeled] for handling connections to multiple databases in the same application.

See:

  * [`Effectful.SQLite.Simple.Labeled`](https://hackage.haskell.org/package/sqlite-simple-effectful/docs/Effectful-SQLite-Simple-Labeled.html)
  * [`Effectful.SQLite.Simple.RW.Labeled`](https://hackage.haskell.org/package/sqlite-simple-effectful/docs/Effectful-SQLite-Simple-RW-Labeled.html)

Credits
---

The API was inspired by [effectful-postgresql](https://hackage.haskell.org/package/effectful-postgresql).

[labeled]: https://hackage-content.haskell.org/package/effectful-core/docs/Effectful-Labeled.html

\begin{code}%hidden
-- Utils

data User
instance FromRow User where fromRow = undefined
\end{code}
