\begin{code}%hidden
{-# LANGUAGE GHC2024 #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedStrings #-}

module Readme.Pooled where

-- imports needed for the "utils" at the bottom.
import Effectful.SQLite.Simple (FromRow(..))
import Database.SQLite.Simple.FromField (FromField(..))
import Database.SQLite.Simple.ToField (ToField)
import Data.Text (Text)

\end{code}

The module [`Effectful.SQLite.Simple.RW`](https://hackage.haskell.org/package/sqlite-simple-effectful/docs/Effectful-SQLite-Simple-RW.html)
provides an interpreter backed by connection pools.

SQLite allows multiple connections to read/write concurrently, but concurrent writes will lead to
[contention, performance degradation, and SQLITE_BUSY errors](https://emschwartz.me/psa-your-sqlite-connection-pool-might-be-ruining-your-write-performance/).
We avoid this by:

  * Having separate pools for reading and writing.
  * Configuring the write pool to have a maximum of 1 connection, thus serializing all writes.

We additionally set the database's journal mode to [WAL](https://sqlite.org/wal.html),
so that readers will not block the writer and the writer will not block readers.

Note that even in WAL mode, [SQLITE_BUSY errors can still occur](https://sqlite.org/wal.html#sometimes_queries_return_sqlite_busy_in_wal_mode).

The `useReadConnection` and `useWriteConnection` operations retrieve a pooled connection
from the context that can be used to run "read" or "write" operations.

\begin{code}
import Effectful.SQLite.Simple.RW (SQLite)
import Effectful.SQLite.Simple.RW qualified as SQL

import Effectful
import Effectful.Concurrent.Async (runConcurrent, concurrently)
import Effectful.Fail (Fail, runFail)
import Control.Monad (void)
import Data.Function ((&))

reader :: (SQLite :> es) => Eff es [User]
reader = do
  SQL.useReadConnection \conn -> do
    SQL.query_ conn "SELECT * FROM users"

writer :: (SQLite :> es, Fail :> es) => Eff es ()
writer = do
  SQL.useWriteConnection \conn -> do
    SQL.withImmediateTransaction conn do
      [userId :: SQL.Only UserId] <- SQL.query conn "SELECT id FROM users WHERE username = ?" (SQL.Only @Text "dcastro")
      SQL.execute conn "DELETE FROM articles WHERE author_id = ?" userId
\end{code}


\begin{code}
main :: IO (Either String ())
main = do
  let dbPath = "users.db"
  pools <-
    SQL.newPools
      =<< SQL.newPoolsConfig
        (SQL.open dbPath) -- Action to create a new read connection.
        60                -- Read connections' idle timeout in seconds.
        32                -- Max number of read connections.
        (SQL.open dbPath) -- Action to create a new write connection.
        60                -- Write connections' idle timeout in seconds.

  let app = void $ concurrently (void reader) writer

  app
    & SQL.runSQLiteWithPools pools
    & runConcurrent
    & runFail
    & runEff
\end{code}


\begin{code}%hidden
-- Utils
data User
instance FromRow User where fromRow = undefined

newtype UserId = UserId Int
  deriving newtype (FromField, ToField)
\end{code}
