# simTools Scripts Documentation


simTools is an useful utility library for our qdex module development. simTools.xml should include all common useful global computing functions. All functions in simTools.xml must implement as global.

**plotTools.xml file should be in the same directory as simTools.xml.**

## Table of Content
  - [Installation](#installation)
  - [Functions](#functions)
    - [round(value, mutiple)](#round)
    - [clone(T)](#clone)
    - [getTableSize(T)](#getTableSize)
  - [World](#world)
    - [new(o)](#world_new)
    - [add(obj)](#world_add)
    - [findIndexOf(obj)](#world_findIndexOf)
    - [removeAtIndex(i)](#world_removeAtIndex)
    - [setDeltaT(t)](#world_setDeltaT)
    - [updateTransform()](#world_updateTransform)
    - [update(updateTransform)](#world_update)
  - [Ball](#ball)
    - [new(o)](#ball_new)
    - [initDrawing()](#ball_initDrawing)
    - [handleCollisionWith(ball)](#ball_handleCollisionWith)
    - [resolveBorderCollisionWith(world)](#ball_resolveBorderCollisionWith)
    - [updatePosition(deltaT)](#ball_updatePosition)
    - [getMomentum()](#ball_getMomentum)

## <a name="installation"></a>Installation

  - Download simTools.xml from Github
  - Move simTools.xml into your module folder
  - Include plotTools.xml into the same directory as simTools.xml
  - Include following code right below `<metadata></metadata>`
      ```xml
      <include src="simTools.xml" />
      ```

## <a name="functions"></a>Functions
  - ### <a name="round"></a>round(value, mutiple)
    ***
    Round a value to user desired precise unit.

    **params:**

    `value`: a number you want to round
    
    `mutiple`: the unit you want your value to round

    **example:**
    ```lua
        x = round(5.25, 0.1)
        y = round(1.3, 1)
        z = round(3.4, 0.3)
    ```
    `x = 5.3`
    `y = 1.0`
    `z = 3.3`
    
  - ### <a name="getTableSize"></a>getTableSize(T)
    ***
    get table size

    **params:**

    `T`: the table
    
    **example:**
    ```lua
        t = {1,2,3,4,5}
        getTableSize(t)
    ```
    `5`
    
  - ### <a name="clone"></a>clone(T)
    ***
    deep copy a table

    **params:**

    `T`: the table
    
    **example:**
    ```lua
        t = {1,2,3,4,5}
        clone(t)
    ```
    `{1,2,3,4,5}`

## <a name="world"></a>World

A simple 2-D World object contains all balls you want to simulate collisions. You can include borders (minX,minY,maxX,maxY) to allow balls bouncing back.

  - ### <a name="world_new"></a>new(o)
    ***
    Create a World object

    **params:**

    `o`: initial table:
       
      - table parameters:
        
        - minX: minimum x boundary
        - minY: minimum y boundary
        - maxX: maximum x boundary
        - maxY: maximum y boundary
        - balls: balls in the world
        - deltaT=0.01: step time interval (simulation period)

    **example:**
    ```lua
        local world = World:new({minX=5,minY=-5,maxX=10,maxY=20,balls={ball1,ball2....},deltaT=0.05})
    ```
    
  - ### <a name="world_add"></a>add(ball)
    ***
    add a ball to the world

    **params:**

    `ball`: the new Ball object
    
    **example:**
    ```lua
        local ball = Ball:new({x=5,y=3,velocity={1,1}})
        world:add(ball)
    ```
    
  - ### <a name="world_findIndexOf"></a>findIndexOf(obj)
    ***
    find the index of a ball, return -1 if not found

    **params:**

    `obj`: the ball
    
    **example:**
    ```lua
        world:findIndexOf(ball)
    ```
    
  - ### <a name="world_removeAtIndex"></a>removeAtIndex(i)
    ***
    Remove a ball from world by providing its index

    **params:**

    `i`: the ball index
    
    **example:**
    ```lua
        world:removeAtIndex(i)
    ```
    
      - ### <a name="world_setDeltaT"></a>setDeltaT(t)
    ***
    set delta time to t

    **params:**

    `t`: the delta time
    
    **example:**
    ```lua
        world:setDeltaT(t)
    ```
    
  - ### <a name="world_updateTransform"></a>updateTransform()
    ***
    Update transformation of balls to its current location
    ALL balls must provide their series!
    
    **example:**
    ```lua
        world:updateTransform()
    ```
    
  - ### <a name="world_update"></a>update(updateTransform)
    ***
    Update World by one deltaT.

    **params:**

    `updateTransform`: if this field is true, world will automatically update all balls transformation
    
    **example:**
    ```lua
        world:update(true)
    ```

## <a name="ball"></a>Ball

A simple Ball object handles 2-D collision. 

  - ### <a name="ball_new"></a>new(o)
    ***
    Create a Ball object

    **params:**

    `o`: initial table:
       
      - table parameters:
        {x, y, radius=1, mass=0, velocity={0,0}, series};
        - x: x coordinate
        - y: y coordinate
        - radius=1: ball radius
        - mass: ball mass
        - velocity={0,0}: ball velocity, a table contains xy components
        - series: drawing series, every ball should have its own series, and every ball series is recommanded to be set.

    **example:**
    ```lua
        local ball = Ball:new({x=5,y=12,radius=2,mass=10,velocity={10,5},series=simStack.drawing.series1})
    ```

  - ### <a name="ball_initDrawing"></a>initDrawing()
    ***
    Clear series, draw the ball and move to its location. ball series must be provided.
    
    **example:**
    ```lua
        local ball1 = Ball:new({x=5,y=3,velocity={1,1}})
        ball1:initDrawing()
    ```

  - ### <a name="ball_handleCollisionWith"></a>handleCollisionWith(ball)
    ***
    handle collision with the other ball

    **params:**

    `ball`: the other Ball object
    
    **example:**
    ```lua
        local ball1 = Ball:new({x=5,y=3,velocity={1,1}})
        local ball2 = Ball:new({x=10,y=3,velocity={-5,-3}})
        ball1:handleCollisionWith(ball2);
    ```
    
  - ### <a name="ball_resolveBorderCollisionWith"></a>resolveBorderCollisionWith(world)
    ***
    check and change velocity for ball in the given world if border is given

    **params:**

    `world`: the world
    
    **example:**
    ```lua
        ball:resolveBorderCollisionWith(world)
    ```
    
  - ### <a name="ball_updatePosition"></a>updatePosition(deltaT)
    ***
    Update the ball position for one delta time

    **params:**
    
    `deltaT`: step time (simulation period)
    
    **example:**
    ```lua
        ball:updatePosition(0.02)
    ```
    
  - ### <a name="ball_getMomentum"></a>getMomentum()
    ***
    Get momentum of the ball
    
    **example:**
    ```lua
        ball:getMomentum()
    ```
    
    
    
