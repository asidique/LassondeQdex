# simTools Scripts Examples


## 2D World Balls Collision Simulation Example
```xml
<drawing name="drawing">
  <axis dim="x" min="0" max="40" auto="fixed" />
  <axis dim="y" min="0" max="30" auto="fixed" />
  <series name="ball1" draw="radialFill" capacity="800" style="quanserRedF" />
  <series name="ball2" draw="radialFill" capacity="800" style="dodgerBlueF" />
  <series name="ball3" draw="radialFill" capacity="1600" style="forestGreenF" />
</drawing>

<script>
  <![CDATA[
    local myPlot = {}
    local world
    
    function myPlot:updateWorld()
      world:update(true)
    end
			
    function myPlot:init()
      -- create all Ball objects
      local ball1 = Ball:new({mass=5,velocity={2,0}, x=11, y=16, series=drawing.ball1})
      local ball2 = Ball:new({mass=2.5,velocity={0,0}, x=20, y=15, radius=0.5, series=drawing.ball2})
      local ball3 = Ball:new({mass=10,velocity={-0.25, -0.25},x=27,y=20,radius=2, series=drawing.ball3})
      
      -- create World object (with boundaries, which will reflect balls)
      world = World:new({minX=0, maxX=40, minY=0, maxY=30, deltaT=0.05, balls={ball1,ball2,ball3}})
		  
      -- initial Drawings
      for i=1,#world.balls do
        world.balls[i]:initDrawing()
      end		
    end
			
    myPlot:init()
  ]]>
</script>

<button name="btn" content="Start Simulation">
  <onClick>
    <![CDATA[
      if btn.Text == "Start Simulation" then
        btn.Text = "Pause Simulation"
        sim:Play();
      else
        btn.Text = "Start Simulation";
        sim:Pause();
      end
    ]]>
  </onClick>
</button>

<simulation name="sim" loop="true" period="0.01">
  <onUpdate>
    myPlot:updateWorld()
  </onUpdate>
</simulation>
```
