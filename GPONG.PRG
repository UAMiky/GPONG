/*
 * GALAX PONG
 *
 * Copyright 2020 Miguel Company (UAMike)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

program GPONG;

const
    PATH_USER = "UAMIKE";
    PATH_PROG = "GPONG";

    PLAYER_STATE_DEAD = -1;
    PLAYER_STATE_MOVING = 1;
    PLAYER_STATE_DYING = 2;

    MAX_VELOCITY = 6;
    SHOOT_CADENCE = 100;
    MAX_LIFES = 3;
    SCORE_FOR_NEW_LIFE = 1000;

    GRAPH_BACKGROUND = 1;
    GRAPH_SCORE_HIPHEN = 40;
    PLAYER_GRAPH = 13;

    MIN_Y = 16;
    MAX_Y = 360 - 16;

    SQUAD_INITIAL_X = 20;
    SQUAD_INITIAL_Y = 60;
    ENEMY_WIDTH = 20;
    ENEMY_HEIGHT = 20;
    SQUAD_MOVEMENT = 1;

    PLAYER_INVULNERABLE_TIME = 150;

global
    struct player_t[1]
        int pid;
        int state;
        int lifes;
        int vel;
        int next_shoot_time;
        int missile_id;
        int enemies;
        int score;
    end =
    2 DUP (0, PLAYER_STATE_DEAD, 3, 0, 0, 0, 0, 0);

    int single_player_mode = false;
    int single_player_score = 0;
    int next_life_score = 0;

    int g_file;
    int snd_laser;
    int snd_laser2;
    int snd_explosion;
    int snd_atack1;
    int snd_atack3;

    int squad_dir = 0;
    int change_dir = 0;
    int squad_y;

local
    int n;

begin
    load_resources();
    config_game();
    // main_menu();

    quick_test();

    debug;
    exit("Fin", 0);
end

function quick_test()
begin
    // game_two_players();
    // loop frame; end

    n = 0;
    loop
        if (n == 0)
            n = game_one_player(false);
        end
        frame;
    end
end

/////////////////
//// CONFIGURATION
/////////////////
function load_resources()
begin
    g_file = load_fpg(path_resolve("GPONG.FPG"));

    snd_laser = load_pcm(path_resolve("laser.pcm"),0);
    snd_laser2 = load_pcm(path_resolve("laser2.pcm"),0);
    snd_explosion = load_pcm(path_resolve("laser3.pcm"),0);
    snd_atack1 = load_pcm(path_resolve("buiu.pcm"),0);
    snd_atack1 = load_pcm(path_resolve("fx1.pcm"),0);

end

function config_game()
begin
    set_mode(m640x400);
    set_fps(24, 0);
    background(g_file, GRAPH_BACKGROUND);
end

process background(file, graph)
begin
    x = 320; y = 200; z = min_int + 2;
    loop frame; end
end

/////////////////
//// LEVEL CONTROLLERS
/////////////////

process game_one_player(brain_fucking)
private
    int id_lifes;
begin
    player_t[0].lifes = 0;
    player_t[1].lifes = 0;

    for (x = 0; x < MAX_LIFES; x++)
        add_life();
    end

    single_player_mode = true;
    single_player_score = 0;
    next_life_score = SCORE_FOR_NEW_LIFE;

    text_z = min_int + 1;
    write(0, 242, 10, 3, "LIFES");
    write(0, 320, 10, 4, "SCORE");
    write_int(0, 320, 20, 4, &single_player_score);
    write(0, 398, 10, 5, "LIFES");

    id_lifes = life_marker();

    n = 0;
    repeat
        n++;
        level_one_player(brain_fucking, n);
    until (player_t[0].state == PLAYER_STATE_DEAD or
           player_t[1].state == PLAYER_STATE_DEAD);

    // TODO: Show highscore

    delete_text(all_text);
    signal(id_lifes, s_kill_tree);

    // Inform father that we are dead
    father.n = 0;
end

function level_one_player(brain_fucking, level)
begin
    player(0, 16, 180, 0, -90000);
    player(1, 640-16, 180, 1, -90000);

    // Invert controls on brain fucking mode
    if (brain_fucking)
        keyb_input(1, _q, _a, _x);
        keyb_input(0, _p, _l, _m);
    else
        keyb_input(0, _q, _a, _x);
        keyb_input(1, _p, _l, _m);
    end

    squad_y = SQUAD_INITIAL_Y;
    squad_dir = 1;
    change_dir = 0;

    player_t[0].enemies = player_t[1].enemies = 12 * 3;
    for(x = 0; x < 12; x++)
        enemy(0, 0, x, 3, level);
        enemy(1, 0, x, 3, level);
    end
    for(x = 0; x < 12; x++)
        enemy(0, 1, x, 2, level);
        enemy(1, 1, x, 2, level);
    end
    for(x = 0; x < 12; x++)
        enemy(0, 2, x, 1, level);
        enemy(1, 2, x, 1, level);
    end

    fade_on();

    repeat
        frame;
        if (squad_dir == 0)
            squad_y -= SQUAD_MOVEMENT;
        else
            squad_y += SQUAD_MOVEMENT;
        end

        if (change_dir == 1)
            squad_dir = squad_dir xor 1;
            change_dir = 0;
        end
    until ( (player_t[0].enemies == 0 and player_t[1].enemies == 0) or    // All enemies killed or
            (player_t[0].state == PLAYER_STATE_DEAD) or                   // left player is dead or
            (player_t[1].state == PLAYER_STATE_DEAD) );                   // right player is dead

    signal(id, s_freeze_tree);
    fade_off();
    signal(id, s_kill_tree);
end

function add_life()
begin
    if (player_t[0].lifes < MAX_LIFES)
        player_t[0].lifes++;
    end

    if (player_t[1].lifes < MAX_LIFES)
        player_t[1].lifes++;
    end
end

process life_marker()
begin
    priority = min_int + 1;
    define_region (1, 240, 10, 80, 30);
    define_region (2, 320, 10, 80, 30);

    for (x = 0; x < MAX_LIFES; x++)
        n = simple_sprite(250 + x * 20, 20, min_int + 1, g_file, PLAYER_GRAPH);
        n.region = 1;
        n = simple_sprite(390 - x * 20, 20, min_int + 1, g_file, PLAYER_GRAPH);
        n.region = 2;
    end

    loop
        define_region (1, 240, 10,
                       20 * player_t[0].lifes, 30);
        define_region (2, 400 - 20 * player_t[1].lifes, 10,
                       20 * player_t[1].lifes, 30);
        frame;
    end
end

process score(n, x, y, z, file)
begin
    loop
        graph = 30 + player_t[n].score;
        frame;
    end
end

function show_help()
begin
    write(0, 20, 30, 0, "Q - MOVE UP");
    write(0, 20, 40, 0, " A - MOVE DOWN");
    write(0, 20, 50, 0, "   X - SHOOT");
    write(0, 20, 70, 0, "PRESS SPACE TO START");

    write(0, 620, 30, 2, "MOVE UP - P");
    write(0, 620, 40, 2, "MOVE DOWN - L ");
    write(0, 620, 50, 2, "SHOOT - M   ");
    write(0, 620, 70, 2, "PRESS SPACE TO START");

    repeat frame; until(key(_space));

    delete_text(all_text);
end

process game_two_players()
begin
    score(0, 275, 175, min_int+1, g_file);
    score(1, 365, 175, min_int+1, g_file);
    simple_sprite(320, 175, min_int+1, g_file, GRAPH_SCORE_HIPHEN);

    show_help();

    loop
        player_t[0].score = 0;
        player_t[1].score = 0;


        fade_off();

        n = 0;
        repeat
            n++;
            level_two_players(n);
        until (player_t[0].score == 9 or player_t[1].score == 9);

        fade_on();
        frame(fps * 400);

        show_help();
    end
end

function level_two_players(level)
begin

    player(0, 16, 180, 0, -90000);
    keyb_input(0, _q, _a, _x);

    player(1, 640-16, 180, 1, -90000);
    keyb_input(1, _p, _l, _m);

    squad_y = SQUAD_INITIAL_Y;
    squad_dir = 1;
    change_dir = 0;

    player_t[0].enemies = player_t[1].enemies = 12 * 3;
    for(x = 0; x < 12; x++)
        enemy(0, 0, x, 3, level);
        enemy(1, 0, x, 3, level);
    end
    for(x = 0; x < 12; x++)
        enemy(0, 1, x, 2, level);
        enemy(1, 1, x, 2, level);
    end
    for(x = 0; x < 12; x++)
        enemy(0, 2, x, 1, level);
        enemy(1, 2, x, 1, level);
    end

    fade_on();

    repeat
        frame;
        if (squad_dir == 0)
            squad_y -= SQUAD_MOVEMENT;
            // if (squad_y < 0) change_dir = 1; end
        else
            squad_y += SQUAD_MOVEMENT;
            // if (squad_y > 360) change_dir = 1; end
        end

        if (change_dir == 1)
            squad_dir = squad_dir xor 1;
            change_dir = 0;
        end
    until (player_t[0].enemies == 0 or player_t[1].enemies == 0);

    if (player_t[0].enemies == 0)
        player_t[0].score++;
    else
        player_t[1].score++;
    end

    signal(id, s_freeze_tree);
    fade_off();
    signal(id, s_kill_tree);
end

/////////////////
//// PLAYER AND CONTROL
/////////////////
process player(n, x, y, flags, angle)
private
    id_collision;
begin
    player_t[n].pid = id;
    player_t[n].state = PLAYER_STATE_MOVING;
    player_t[n].vel = 0;
    player_t[n].next_shoot_time = 0;
    player_t[n].missile_id = 0;
    player_invulnerable(id);

    file = g_file;

    while (player_t[n].state != PLAYER_STATE_DEAD)
        switch (player_t[n].state)
            case PLAYER_STATE_MOVING:
                y += player_t[n].vel;
                y = clamp (y, MIN_Y, MAX_Y);
                graph = PLAYER_GRAPH;

                if (flags < 4)
                    id_collision = collision (TYPE missile);
                    if (id_collision)
                        if (id_collision.n != n)
                            kill_missile(id_collision);
                            player_starts_dying(n);
                        end
                    end
                end
                frame;
            end

            case PLAYER_STATE_DYING:
                explosion(x, y, 100);
                player_finished_dying(n);
            end

            default:
                frame;
            end
        end
    end
end

process player_invulnerable(player_id)
private end_time;
begin
    player_id.flags += 4;
    end_time = timer[0] + PLAYER_INVULNERABLE_TIME;
    while(timer[0] < end_time)
        frame;
    end
    player_id.flags -= 4;
end

function player_starts_dying(n)
begin
    player_t[n].vel = 0;
    player_t[n].state = PLAYER_STATE_DYING;

    // Decrement lifes in single player mode
    if (single_player_mode)
        player_t[n].lifes -= 1;
    end
end

function player_finished_dying(n)
begin
    if (player_t[n].lifes == 0)
        player_t[n].state = PLAYER_STATE_DEAD;
    else
        player_t[n].state = PLAYER_STATE_MOVING;
        player_invulnerable(player_t[n].pid);
    end
end

function try_to_shoot(n)
begin
    if ( (timer[0] >= player_t[n].next_shoot_time) or
         (player_t[n].missile_id == 0) )
        player_t[n].next_shoot_time = timer[0] + SHOOT_CADENCE;
        player_t[n].missile_id = missile(n);
        sound(snd_laser, 40, 50);
    end
end

function throttle_update(n, throttle)
begin
    if (throttle == 0)
        player_t[n].vel = lerp(player_t[n].vel, 0, 100 - (100 / MAX_VELOCITY));
    else
        player_t[n].vel = clamp(player_t[n].vel + throttle, -MAX_VELOCITY, MAX_VELOCITY);
    end
end

process keyb_input(n, up_key, down_key, shoot_key)
private
    throttle = 0;
begin
    priority = player_t[n].pid.priority + 1;

    repeat
        if (player_t[n].state == PLAYER_STATE_MOVING)
            if (key(shoot_key))
                try_to_shoot(n);
            end

            throttle = 0;
            if (key(up_key))
                if (!key(down_key))
                    throttle = -1;
                end
            else if (key(down_key))
                throttle = 1;
            end end
            throttle_update(n, throttle);
        end
        frame;
    until (player_t[n].state == PLAYER_STATE_DEAD);
end

process missile(n)
private
    dir, id_collision;
begin
    x = player_t[n].pid.x;
    y = player_t[n].pid.y;
    flags = player_t[n].pid.flags & 3;
    angle = player_t[n].pid.angle;
    graph = 14;

    if (n == 0)
        dir = 8;
        x += 10;
    else
        dir = -8;
        x -= 10;
    end

    repeat
        frame;
        if (graph == 14) graph = 15; else graph = 14; end
        x += dir;
    until (out_region(id, 0));
    // until (x>260 and x<380);

    if (player_t[n].missile_id == id)
        player_t[n].missile_id = 0;
    end
end

function kill_missile(id_missile)
begin
    if (player_t[id_missile.n].missile_id == id_missile)
        player_t[id_missile.n].missile_id = 0;
    end
    signal(id_missile, s_kill);
end

/////////////////
//// EXPLOSION
/////////////////
function explosion(x,y,size);
begin
    sound(snd_explosion, 80, 100);
    graph=19;
    repeat
        if (size > 50 and rand(0,100)<size/10)
            clone
                x+=rand(-8,8);
                y+=rand(-8,8);
            end
        end
        size-=2;
        frame;
    until (size<25)
end

/////////////////
//// ENEMIES
/////////////////
//------------------------------------------------------------------------------
// Proceso enemigo
// Proceso para las naves enemigas
// 1-crea el enemigo y lo pone en la posici¢n dentro del escuadr¢n.
// 2-controla la acci¢n del enemigo cuando la variable indique que baje.
// Empieza con abajo=0 (Quedarse en la posici¢n de escuadr¢n).
//------------------------------------------------------------------------------

PROCESS enemy(n, row, col, kind, level)

PRIVATE
    num_aleatorio;      // Para n£meros aleatorios
    id_proceso;         // Identificador de uso general.
    ahora=0;            // Numero de animaci¢n
    animacion[]=        // Configuraci¢n de la animaci¢n
        8,9,10,11,10,9;
    abajo=0;            // 0=Posicion de escuadr¢n, 1=ataque,
                        // 3=retorna a la posici¢n de escuadr¢n
    velocidad;          // Velocidad horizontal cuando atacan
    idnave;
    aux_x;

BEGIN
    idnave = player_t[n].pid;
    angle = idnave.angle;
    flags = idnave.flags & 3;
    y = col * ENEMY_WIDTH + squad_y;   // Selecciona posici¢n inicial
    aux_x = row * ENEMY_HEIGHT + SQUAD_INITIAL_X;

    SWITCH (kind)           // Selecciona el gr fico del enemigo
        case 1: graph = 2; END
        case 2: graph = animacion[0]; END
        case 3: graph = 12; END
    END

    LOOP
        IF (kind == 1)        // Animaci¢n de enemigos tipo 1
            graph++;
            IF (graph == 7) graph = 2; END
        END

        IF (kind == 2)        // Animaci¢n de enemigos tipo 2
            ahora++;
            IF (ahora > 5) ahora = 0; END
            graph = animacion[ahora];
        END

        IF (aux_x < 130)                  // Puede disparar si vuela bajo
            num_aleatorio = rand(0,1500);     // Porcentaje de disparo
            IF (kind == 3 AND num_aleatorio <= level * 2)
                enemy_fire(n, x, y, -1, 18, 18);
            END
            IF (kind == 2 AND num_aleatorio <= level)
                enemy_fire(n, x, y, -1, 16, 17);
            END
        END

        IF (abajo == 1)           // Ataca la nave
            aux_x += 2;
            // Comprueba si ha salido de pantalla
            IF (out_region(id,0))
                // Cambia las coordenadas a arriba
                aux_x = 0;
                y = col * ENEMY_WIDTH + squad_y;
                abajo = 3;
            END
            IF (y > idnave.y)     // Va hacia la nave del jugador
                IF (velocidad > -kind-2) velocidad--; END
            ELSE
                IF (velocidad < kind + 2) velocidad++; END
            END
            y += velocidad;
        END

        IF (abajo == 3)           // Retorna a la posici¢n de escuadr¢n
            aux_x++;
            IF (aux_x == row * ENEMY_HEIGHT + SQUAD_INITIAL_X) abajo = 0; END
            // Si hay menos enemigos que el level por 3 vuelve a bajar
            IF (player_t[n].enemies < level * 3) abajo = 1; END
        END

        IF ((abajo == 0) OR (abajo == 3)) // Mueve al escuadr¢n
            num_aleatorio = rand(1,4000);
            // Aleatoriamente y seg£n el level hace que el proceso baje
            IF (num_aleatorio < level * 2)
                abajo = 1;
                IF (kind == 3)
                    sound(snd_atack3, 200, 300);
                END
                IF (kind == 1)
                    sound(snd_atack1, 200, 300);
                END
            END

            IF (squad_dir == 0)         // Si la direcci¢n es hacia la izquierda
                y -= SQUAD_MOVEMENT;

                // Cuando no se pueda mover a la izquierda cambia de direcci¢n
                IF (y < 20) change_dir = 1; END

            ELSE                // Si la direcci¢n es a la derecha
                y += SQUAD_MOVEMENT;
                IF (y > 340) change_dir = 1; END // Cambia la direcci¢n
            END
        END

        if (n == 0)
            x = 240 - aux_x;
        else
            x = 400 + aux_x;
        end

        // Mata la nave del jugador cuando colisione con ella
        IF (idnave.flags < 4 and collision(TYPE player))
            player_starts_dying(n);
            player_t[n].enemies--;
            break;
        ELSE
            id_proceso = collision(TYPE missile);
            IF (id_proceso)
                kill_missile(id_proceso);
                single_player_score += kind * 10;
                if (single_player_score >= next_life_score)
                    next_life_score += SCORE_FOR_NEW_LIFE;
                    add_life();
                end
                player_t[n].enemies--;
                graph = 0;
                explosion(x, y, 100);
                break;
            END
        END

        FRAME;
    END
END

process enemy_fire(n, x, y, z, graph1, graph2)
private
   vel_x = 300, vel_y;
begin
    sound(snd_laser2, 256, 300);
    graph=graph1;
    angle=player_t[n].pid.angle;
    flags=player_t[n].pid.flags & 3;
    resolution=100;

    if (n == 0) vel_x *= -1; end
    vel_y = player_t[n].pid.y - y;
    if (vel_y != 0)
        vel_y = (vel_y * vel_x) / (player_t[n].pid.x - x);
        vel_y = clamp(vel_y, -100, 100);
    end

    y *= resolution;
    x *= resolution;

    repeat
        if (graph == graph1)
            graph = graph2;
        else
            graph = graph1;
        end

        x += vel_x;
        y += vel_y;

        if (player_t[n].pid.flags < 4 and collision (TYPE player))
            player_starts_dying(n);
            break;
        end

        frame;
    until (out_region(id,0))

end


/////////////////
//// HELPER TOOLS
/////////////////
function clamp(value, min, max)
begin
    if (value < min) return (min); end
    if (value > max) return (max); end

    return (value);
end

function lerp(a, b, t)
begin
    return ((a * t + b * (100 - t)) / 100);
end

process simple_sprite(x, y, z, file, graph)
begin
    loop
        frame;
    end
end

function path_resolve(file)
begin
    return (PATH_USER + "\" + PATH_PROG + "\" + file);
end
