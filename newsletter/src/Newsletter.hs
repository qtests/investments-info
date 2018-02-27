{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}

module Newsletter
  ( sesEmail
  ) where

import           Data.ByteString (ByteString)
import qualified Data.ByteString.Lazy as L
import           Data.Text (Text, pack)
import           Network.SES (PublicKey (..), Region (USEast1), SESResult (..), SecretKey (..),
                              sendEmailBlaze)
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A

awsAccessKey :: ByteString
awsAccessKey = "AKIAI6GDZ5ELIC7ABKJA"

awsSecretKey :: ByteString
awsSecretKey = "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"

data News = News
    { _nTitle :: Text
    , _nLink  :: Text
    } deriving (Show)

sesEmail :: [L.ByteString] -> [News] -> IO (Either Text Text)
sesEmail to n =
  sendMail to n >>= \case
    Error e -> return $ Left $ pack (show e)
    Success -> return $ Right (pack "success")

sendMail :: [L.ByteString] -> [News] -> IO SESResult
sendMail emailList n =
  sendEmailBlaze publicKey secretKey region from to subject html
  where
    publicKey = PublicKey awsAccessKey
    secretKey = SecretKey awsSecretKey
    region = USEast1
    from = "contact@investments-info.com"
    subject = "Test Subject"
    to = emailList
    html =
      H.html $ do
        H.body $ do
          H.img H.! A.src "http://haskell-lang.org/static/img/logo.png"
          H.h1 "Html email! Hooray"
