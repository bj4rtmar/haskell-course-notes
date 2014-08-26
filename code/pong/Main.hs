module Main(main, PongGame(Game, player2)) where

import Graphics.Gloss
import Graphics.Gloss.Interface.Pure.Game

width, height, offset :: Int
width = 300
height = 300
offset = 100

window :: Display
window = InWindow "Pong" (width, height) (offset, offset)

background :: Color
background = black

-- | Number of frames to show per second.
fps :: Int
fps = 60

type Radius = Float
type Position = (Float, Float)

-- | Given position and radius of the ball, return whether a collision occurred.
wallCollision :: Position -> Radius -> Bool
wallCollision (_, y) radius = topCollision || bottomCollision
  where
    topCollision    = y - radius <= -fromIntegral width / 2
    bottomCollision = y + radius >=  fromIntegral width / 2

wallBounce :: PongGame -> PongGame
wallBounce game = game { ballVel = (vx, vy') }
  where
    -- Radius. Use the same thing as in `render`.
    radius = 10

    -- The old velocities.
    (vx, vy) = ballVel game

    vy' = if wallCollision (ballLoc game) radius
          then 
             -- Update the velocity.
             -vy
           else
            -- Do nothing. Return the old velocity.
            vy

main :: IO ()
main = play window background fps initialState render handleKeys update


-- | Respond to key events.
handleKeys :: Event -> PongGame -> PongGame

-- For an 's' keypress, reset the ball to the center.
handleKeys (EventKey (Char 's') _ _ _) game =
  game { ballLoc = (0, 0) }

-- Do nothing for all other events.
handleKeys _ game = game


-- | Update the game by moving the ball.
-- Ignore the ViewPort argument.
update :: Float -> PongGame -> PongGame
update seconds = const (error "Player 1 wins") . wallBounce . moveBall seconds


-- | Update the ball position using its current velocity.
moveBall :: Float    -- ^ The number of seconds since last update
         -> PongGame -- ^ The initial game state
         -> PongGame -- ^ A new game state with an updated ball position
moveBall seconds game = game { ballLoc = (x', y') }
  where
    -- Old locations and velocities.
    (x, y) = ballLoc game
    (vx, vy) = ballVel game

    -- New locations.
    x' = x + vx * seconds
    y' = y + vy * seconds



drawing :: Picture
drawing = render initialState


render :: PongGame -> Picture
render game =
  pictures [ball, walls,
            mkPaddle rose 120 $ player1 game,
            mkPaddle orange (-120) $ player2 game]
  where
    --  The pong ball.
    ball = uncurry translate (ballLoc game) $ color ballColor $ circleSolid 10
    ballColor = dark red

    --  The bottom and top walls.
    wall :: Float -> Picture
    wall offset =
      translate 0 offset $
        color wallColor $
          rectangleSolid 270 10

    wallColor = greyN 0.5
    walls = pictures [wall 150, wall (-150)]

    --  Make a paddle of a given border and vertical offset.
    mkPaddle :: Color -> Float -> Float -> Picture 
    mkPaddle col x y = pictures
      [ translate x y $ color col $ rectangleSolid 26 86
      , translate x y $ color paddleColor $ rectangleSolid 20 80
      ]

    paddleColor = light (light blue)

initialState :: PongGame
initialState = Game
  { ballLoc = (-10, 80)
  , ballVel = (10, -60)
  , player1 = 40
  , player2 = 40
  }

-- | Data describing the state of the pong game. 1
data PongGame = Game
  { ballLoc :: (Float, Float)  -- ^ Pong ball (x, y) location.
  , ballVel :: (Float, Float)  -- ^ Pong ball (x, y) velocity. <2>
  , player1 :: Float          -- ^ Left player paddle height.
                               -- Zero is the middle of the screen. <3>
  , player2 :: Float           -- ^ Right player paddle height.
  } deriving Show

