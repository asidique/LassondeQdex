# simTools Scripts Documentation


simTools is an useful utility library for our qdex module development. simTools.xml should include all common useful global computing functions. All functions in simTools.xml must implement as global.

## Table of Content
  - [Installation](#installation)
  - [Functions](#functions)
    - [round(value, mutiple)](#round)

## <a name="installation"></a>Installation

  - Download simTools.xml from Github
  - Move simTools.xml into your module folder
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
