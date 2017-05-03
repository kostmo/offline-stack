{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fwarn-unused-binds -fwarn-unused-imports #-}

import           Control.Monad.Extra
import           Control.Monad.IO.Class
import qualified Data.ByteString.Char8        as BS
import           Data.List.Extra
import           Data.Tuple.Extra
import           Network.HTTP.Types
import           Network.Wai
import           Network.Wai.Handler.Warp
import           System.Directory
import           System.FilePath

import           Control.Monad.Trans.Resource
import qualified Data.Conduit                 as C
import           Data.Conduit.Binary
import           Network
import           Network.Connection
import qualified Network.HTTP.Conduit         as C


mirrorDir = "mirror"

listenPort = 3000


main :: IO ()
main = withSocketsDo $ do
    putStrLn $ "Listening on port " ++ show listenPort
    run listenPort $ \req f -> f =<< app req

app :: Request -> IO Response
app req = do
    let want = tail $ BS.unpack $ rawPathInfo req `BS.append` rawQueryString req
    let url = uncurry (++) $ first (++ ":/") $ break ('/' ==) want
    let file = mirrorDir </> replace "?" "_" (replace "/" "_" want)
    createDirectoryIfMissing True mirrorDir

    -- download the file
    unlessM (doesFileExist file) $ do
        manager <- C.newManager $ C.mkManagerSettings (TLSSettingsSimple True False False) Nothing
        request <- C.parseUrlThrow url
        runResourceT $ do
            response <- C.http request manager
            C.responseBody response C.$$+- sinkFile file
            liftIO $ print $ C.responseStatus response

    -- pass it onwards
    return $ responseFile status200 [] file Nothing
