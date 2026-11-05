# SEPPL
A fun, silly programming language inspired by BASIC and other early programming languages.

## Syntax

```python

REM This is a comment!

IMPORT console

CONST INT MY_FAVOURITE_NUMBER = 0

STRUCT Vector2
    FLOAT x
    FLOAT y
    
    FUNC add(Vector2 other) RETS Vector2
        RET Vector2(self.x + other.x, self.y + other.y)
    END FUNC
END STRUCT

FUNC add(INT a, INT b) RETS INT
    RET a + b
END FUNC

FUNC main() AS VOID
    INT a = 5
    INT b = 4

    INT result = add(a, b)

    Vector2 position = Vector2(10, 20)
    Vector2 offset = Vector2(5, 5)
    Vector2 new_position = position.add(offset)

    console.print(result)

    INT score = INT(console.read())
    
    IF score >= 100 THEN
        console.print("You win!")
    ELSE IF score >= 50 THEN
        console.print("Almost there!")
    ELSE
        console.print("Keep trying!")
    END IF

    INT i = 0
    WHILE i < 10 DO
        console.print(i)
        i = i + 1
        IF i = 4
            CONTINUE
        END IF
        IF i = 9
            BREAK
        END IF END
    END WHILE
END FUNC
```
