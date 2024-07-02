-- create the table 
DROP TABLE IF EXISTS tic_tac_toe;
CREATE TABLE tic_tac_toe (
    id SERIAL PRIMARY KEY,
    x INT NOT NULL,
    y INT NOT NULL,
    value CHAR(1),
    move_number INT
);


-- start game function 
CREATE OR REPLACE FUNCTION NewGame() RETURNS VOID AS $$
BEGIN
    -- Clear the table
    DELETE FROM tic_tac_toe;

    -- Initialize the board with NULL values
    INSERT INTO tic_tac_toe (x, y, value, move_number)
    SELECT x, y, NULL, 0
    FROM generate_series(1, 3) AS x,
         generate_series(1, 3) AS y;

    RAISE NOTICE 'New game started!';
END;
$$ LANGUAGE plpgsql;

--helper functio to deremine the next symbol to place
CREATE OR REPLACE FUNCTION GetNextSymbol() RETURNS CHAR AS $$
DECLARE
    x_count INT;
    o_count INT;
BEGIN
    SELECT COUNT(*) INTO x_count FROM tic_tac_toe WHERE value = 'X';
    SELECT COUNT(*) INTO o_count FROM tic_tac_toe WHERE value = 'O';

    IF x_count <= o_count THEN
        RETURN 'X';
    ELSE
        RETURN 'O';
    END IF;
END;
$$ LANGUAGE plpgsql;


-- helper function to check fo a win or draw 

CREATE OR REPLACE FUNCTION CheckGameResult() RETURNS TEXT AS $$
DECLARE
    winner CHAR(1);
    draw BOOLEAN;
BEGIN
    -- Check rows, columns, and diagonals for a winner
    SELECT value INTO winner
    FROM (
        SELECT value
        FROM tic_tac_toe
        WHERE value IS NOT NULL
        GROUP BY value, x
        HAVING COUNT(*) = 3
        UNION ALL
        SELECT value
        FROM tic_tac_toe
        WHERE value IS NOT NULL
        GROUP BY value, y
        HAVING COUNT(*) = 3
        UNION ALL
        SELECT value
        FROM tic_tac_toe
        WHERE value IS NOT NULL AND x = y
        GROUP BY value
        HAVING COUNT(*) = 3
        UNION ALL
        SELECT value
        FROM tic_tac_toe
        WHERE value IS NOT NULL AND x + y = 4
        GROUP BY value
        HAVING COUNT(*) = 3
    ) AS sub
    LIMIT 1;

    IF winner IS NOT NULL THEN
        RETURN winner || ' wins!';
    END IF;

    -- Check for draw
    SELECT COUNT(*) = 9 INTO draw FROM tic_tac_toe WHERE value IS NOT NULL;

    IF draw THEN
        RETURN 'Draw!';
    END IF;

    RETURN 'Game continues';
END;
$$ LANGUAGE plpgsql;


-- function to make the next move 
CREATE OR REPLACE FUNCTION NextMove(x INT, y INT, val CHAR DEFAULT NULL) RETURNS TEXT AS $$
DECLARE
    current_symbol CHAR;
    game_result TEXT;
    board_state TEXT;
BEGIN
    -- Определить символ, если он не предоставлен
    IF val IS NULL THEN
        current_symbol := GetNextSymbol();
    ELSE
        current_symbol := val;
    END IF;

    -- Обновить доску с новым ходом
    UPDATE tic_tac_toe
    SET value = current_symbol, move_number = move_number + 1
    WHERE tic_tac_toe.x = $1 AND tic_tac_toe.y = $2 AND value IS NULL;

    IF NOT FOUND THEN
        RETURN 'Неверный ход';
    END IF;

    -- Проверить результат игры
    game_result := CheckGameResult();

    -- Вернуть текущее состояние доски
    SELECT string_agg(row_str, E'\n')
    INTO board_state
    FROM (
        SELECT string_agg(COALESCE(value, ' '), '|') AS row_str
        FROM tic_tac_toe
        GROUP BY tic_tac_toe.x
        ORDER BY tic_tac_toe.x
    ) AS rows;

    -- Добавить сообщение о результате игры, если игра окончена
    IF game_result <> 'Игра продолжается' THEN
        RETURN board_state || E'\n' || game_result;
    END IF;

    RETURN board_state;
END;
$$ LANGUAGE plpgsql;

-- Функция для получения текущего состояния доски
CREATE OR REPLACE FUNCTION GetBoardState() RETURNS TEXT AS $$
DECLARE
    board_state TEXT;
BEGIN
    -- Вернуть текущее состояние доски
    SELECT string_agg(row_str, E'\n')
    INTO board_state
    FROM (
        SELECT string_agg(COALESCE(value, ' '), '|') AS row_str
        FROM tic_tac_toe
        GROUP BY tic_tac_toe.x
        ORDER BY tic_tac_toe.x
    ) AS rows;

    RETURN board_state;
END;
$$ LANGUAGE plpgsql;


--start game 

SELECT NewGame();

-- get board 
SELECT GetBoardState();

-- first turn
SELECT NextMove(1, 3); 


