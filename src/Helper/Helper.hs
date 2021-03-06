{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE RecordWildCards       #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}

module Helper.Helper where

import           Data.Maybe (fromJust)
import           Database.Esqueleto as E
import           Database.Esqueleto.Internal.Language
import           Database.Persist.Sql (SqlBackend, rawSql, unSingle)
import           Import

truncateTables
  :: MonadIO m
  => ReaderT SqlBackend m [Text]
truncateTables = do
  result <- rawSql "DELETE FROM 'story';" []
  return (fmap unSingle result)

makeHash
  :: Hashable a
  => a -> Int
makeHash = hash

postsByPage :: Int
postsByPage = 10

selectCount
  :: ( BaseBackend backend ~ SqlBackend
     , Database.Esqueleto.Internal.Language.From SqlQuery SqlExpr SqlBackend t
     , MonadIO m
     , Num a
     , IsPersistBackend backend
     , PersistQueryRead backend
     , PersistUniqueRead backend
     , PersistField a
     )
  => (t -> SqlQuery a1) -> ReaderT backend m a
selectCount q = do
  res <- select $ from (\x -> q x >> return countRows)
  return $ maybe 0 (\(Value a) -> a) (headMay res)

calculatePreviousPage :: Int -> Int -> Page -> Maybe Int
calculatePreviousPage entries pageSize currentPage =
  if n <= entries && n > 0
    then Just n
    else Nothing
  where
    n = (pageSize * (currentPage - 1)) `div` pageSize

calculateNextPage :: Int -> Int -> Int -> Maybe Int
calculateNextPage entries pageSize currentPage =
  if n <= ((entries `div` pageSize) + 1) && n > 0
    then Just n
    else Nothing
  where
    n = (pageSize * (currentPage + 1)) `div` pageSize

-- | Read AWS keys from settings.yml
getAwsKey
  :: MonadIO m
  => Text -> m Text
getAwsKey t = do
  settings <- liftIO $ loadYamlSettings ["config/settings.yml"] [] useEnv
  case t of
    "awsAccessKey"      -> return $ fromJust (awsAccessKey settings)
    "awsSecretKey"      -> return $ fromJust (awsSecretKey settings)
    "awsSesAccessKey"   -> return $ fromJust (awsSesAccessKey settings)
    "awsSesSecretKey"   -> return $ fromJust (awsSesSecretKey settings)
    "mailchimp-api-key" -> return $ fromJust (mailchimpApiKey settings)

    _                   -> error "no such key in settings file!"

-- | Read admin users from settings.yml
getAdmins
  :: MonadIO m
  => m [AdminUsers]
getAdmins = do
  settings <- liftIO $ loadYamlSettings ["config/settings.yml"] [] useEnv
  return $ fromJust (administrators settings)
