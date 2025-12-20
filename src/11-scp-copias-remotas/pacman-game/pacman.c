#include <ncurses.h>
#include <stdbool.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <locale.h>

#define MAP_WIDTH 30
#define MAP_HEIGHT 19
#define PACMAN_CHAR 'C'
#define GHOST_CHAR 'G'
#define DOT '.'
#define POWER 'o'
#define WALL '#'
#define EMPTY ' '

typedef struct {
    int x;
    int y;
    int dx;
    int dy;
} Entity;

typedef struct {
    Entity pos;
    Entity start;
    int frightened_ticks;
} Ghost;

static const char LEVEL_TEMPLATE[MAP_HEIGHT][MAP_WIDTH + 1] = {
    "##############################",
    "#..............##............#",
    "#.####.#####..##..#####.####.#",
    "#o####.#####..##..#####.####o#",
    "#.####.#####..##..#####.####.#",
    "#............................#",
    "#.####.##.########.##.####.###",
    "#.####.##.########.##.####.###",
    "#......##....##....##........#",
    "#.####.#####..##..#####.####.#",
    "#o####.##....##....##.####o###",
    "#.####.##.########.##.####.###",
    "#.####.##.########.##.####.###",
    "#............##..............#",
    "#........##..............##..#",
    "#...##........########.......#",
    "#o..........................o#",
    "#............##............###",
    "##############################"
};

static char map_grid[MAP_HEIGHT][MAP_WIDTH];
static Entity pacman;
static Ghost ghosts[2];
static int lives = 5;
static int score = 0;
static int dots_left = 0;
static int power_timer = 0;
static int tick_count = 0;
static bool colors_on = false;

static void init_colors(void) {
    if (!has_colors()) {
        return;
    }

    start_color();
#ifdef NCURSES_VERSION
    use_default_colors();
#endif
    init_pair(1, COLOR_BLUE, -1);    // Muros
    init_pair(2, COLOR_YELLOW, -1);  // Puntos
    init_pair(3, COLOR_MAGENTA, -1); // Power pellets
    init_pair(4, COLOR_YELLOW, -1);  // Pac-Man
    init_pair(5, COLOR_RED, -1);     // Fantasmas normales
    init_pair(6, COLOR_CYAN, -1);    // Fantasmas asustados
    init_pair(7, COLOR_WHITE, -1);   // Texto UI
    colors_on = true;
}

static int manhattan(int x1, int y1, int x2, int y2) {
    int dx = x1 - x2;
    int dy = y1 - y2;
    return (dx < 0 ? -dx : dx) + (dy < 0 ? -dy : dy);
}

static bool is_wall(int y, int x) {
    if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT) {
        return true;
    }
    return map_grid[y][x] == WALL;
}

static void copy_level(void) {
    dots_left = 0;
    for (int y = 0; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            map_grid[y][x] = LEVEL_TEMPLATE[y][x];
            if (map_grid[y][x] == DOT || map_grid[y][x] == POWER) {
                dots_left++;
            }
        }
    }
}

static void reset_positions(void) {
    pacman.x = 15;
    pacman.y = 5;
    pacman.dx = -1;
    pacman.dy = 0;

    ghosts[0].pos.x = 8;  ghosts[0].pos.y = 10; ghosts[0].pos.dx = 0; ghosts[0].pos.dy = 0;
    ghosts[1].pos.x = 21; ghosts[1].pos.y = 10; ghosts[1].pos.dx = 0; ghosts[1].pos.dy = 0;

    ghosts[0].start = ghosts[0].pos;
    ghosts[1].start = ghosts[1].pos;
    ghosts[0].frightened_ticks = 0;
    ghosts[1].frightened_ticks = 0;
    power_timer = 0;
}

static void draw_scene(void) {
    for (int y = 0; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            chtype glyph = map_grid[y][x];
            int pair = 0;

            switch (map_grid[y][x]) {
                case WALL:
                    glyph = ACS_CKBOARD;
                    if (glyph == 'a' || glyph == 0) {
                        glyph = '#'; // Fallback si el ACS muestra letras en esta terminal
                    }
                    pair = 1;
                    break;
                case DOT:
                    glyph = DOT;
                    pair = 2;
                    break;
                case POWER:
                    glyph = POWER;
                    pair = 3;
                    break;
                default:
                    break;
            }

            if (colors_on && pair > 0) attron(COLOR_PAIR(pair));
            mvaddch(y, x, glyph);
            if (colors_on && pair > 0) attroff(COLOR_PAIR(pair));
        }
    }

    bool mouth_open = (tick_count / 2) % 2 == 0; // Aún más rápido para notar la mordida
    char pac_char = PACMAN_CHAR;
    if (pacman.dx > 0) {            // Derecha
        pac_char = mouth_open ? '<' : '='; // "--" en una sola celda
    } else if (pacman.dx < 0) {     // Izquierda
        pac_char = mouth_open ? '>' : '='; // "--" en una sola celda
    } else if (pacman.dy < 0) {     // Arriba
        pac_char = mouth_open ? 'v' : '|';
    } else if (pacman.dy > 0) {     // Abajo
        pac_char = mouth_open ? '^' : '|';
    } else {
        pac_char = mouth_open ? 'C' : 'O';
    }

    // Dibuja cuerpo justo detrás de la cabeza, sin alterar el mapa lógico
    if (pacman.dx != 0 || pacman.dy != 0) {
        int body_x = pacman.x - pacman.dx;
        int body_y = pacman.y - pacman.dy;
        if (!is_wall(body_y, body_x)) {
            if (colors_on) attron(COLOR_PAIR(4));
            mvaddch(body_y, body_x, 'o');
            if (colors_on) attroff(COLOR_PAIR(4));
        }
    }

    if (colors_on) attron(COLOR_PAIR(4));
    mvaddch(pacman.y, pacman.x, pac_char);
    if (colors_on) attroff(COLOR_PAIR(4));

    for (int i = 0; i < 2; i++) {
        int gp = ghosts[i].frightened_ticks > 0 ? 6 : 5;
        if (colors_on) attron(COLOR_PAIR(gp));
        mvaddch(ghosts[i].pos.y, ghosts[i].pos.x, GHOST_CHAR);
        if (colors_on) attroff(COLOR_PAIR(gp));
    }

    if (colors_on) attron(COLOR_PAIR(7));
    mvprintw(MAP_HEIGHT, 0, "Score: %d  Vidas: %d  Dots: %d  Modo: %s %3d",
             score,
             lives,
             dots_left,
             power_timer > 0 ? "ASUSTADOS" : "PERSECUCION",
             power_timer);
    mvprintw(MAP_HEIGHT + 1, 0, "Controles: Flechas para mover, q para salir");
    if (colors_on) attroff(COLOR_PAIR(7));
    refresh();
}

static void eat_tile(int y, int x) {
    if (map_grid[y][x] == DOT) {
        score += 10;
        dots_left--;
    } else if (map_grid[y][x] == POWER) {
        score += 50;
        dots_left--;
        power_timer = 120;
        for (int i = 0; i < 2; i++) {
            ghosts[i].frightened_ticks = power_timer;
        }
    }
    map_grid[y][x] = EMPTY;
}

static bool can_move(int y, int x) {
    return !is_wall(y, x);
}

static void move_pacman(int input) {
    static int desired_dx = -1;
    static int desired_dy = 0;

    switch (input) {
        case KEY_UP:    desired_dx = 0; desired_dy = -1; break;
        case KEY_DOWN:  desired_dx = 0; desired_dy = 1;  break;
        case KEY_LEFT:  desired_dx = -1; desired_dy = 0; break;
        case KEY_RIGHT: desired_dx = 1; desired_dy = 0;  break;
        default: break;
    }

    int next_x = pacman.x + desired_dx;
    int next_y = pacman.y + desired_dy;

    if (can_move(next_y, next_x)) {
        pacman.dx = desired_dx;
        pacman.dy = desired_dy;
        pacman.x = next_x;
        pacman.y = next_y;
    }

    eat_tile(pacman.y, pacman.x);
}

static void choose_direction(Ghost *g) {
    const int dirs[4][2] = {{1,0},{-1,0},{0,1},{0,-1}};
    int best_dx = 0, best_dy = 0;
    int best_score = 1e9;

    if (g->frightened_ticks > 0) {
        int candidates[4][2];
        int options = 0;
        for (int i = 0; i < 4; i++) {
            int nx = g->pos.x + dirs[i][0];
            int ny = g->pos.y + dirs[i][1];
            if (!is_wall(ny, nx)) {
                candidates[options][0] = dirs[i][0];
                candidates[options][1] = dirs[i][1];
                options++;
            }
        }
        if (options > 0) {
            int pick = rand() % options;
            best_dx = candidates[pick][0];
            best_dy = candidates[pick][1];
        }
    } else {
        for (int i = 0; i < 4; i++) {
            int nx = g->pos.x + dirs[i][0];
            int ny = g->pos.y + dirs[i][1];
            if (is_wall(ny, nx)) {
                continue;
            }
            int dist = manhattan(nx, ny, pacman.x, pacman.y);
            if (dist < best_score) {
                best_score = dist;
                best_dx = dirs[i][0];
                best_dy = dirs[i][1];
            }
        }
    }

    g->pos.dx = best_dx;
    g->pos.dy = best_dy;
}

static void move_ghosts(void) {
    if (tick_count % 3 != 0) {
        return; // Fantasmas se mueven 1 de cada 3 ticks
    }
    for (int i = 0; i < 2; i++) {
        choose_direction(&ghosts[i]);
        int nx = ghosts[i].pos.x + ghosts[i].pos.dx;
        int ny = ghosts[i].pos.y + ghosts[i].pos.dy;
        if (!is_wall(ny, nx)) {
            ghosts[i].pos.x = nx;
            ghosts[i].pos.y = ny;
        }
        if (ghosts[i].frightened_ticks > 0) {
            ghosts[i].frightened_ticks--;
        }
    }
    if (power_timer > 0) {
        power_timer--;
    }
}

static void handle_collisions(bool *running) {
    for (int i = 0; i < 2; i++) {
        if (pacman.x == ghosts[i].pos.x && pacman.y == ghosts[i].pos.y) {
            if (ghosts[i].frightened_ticks > 0) {
                score += 200;
                ghosts[i].pos = ghosts[i].start;
                ghosts[i].frightened_ticks = 0;
            } else {
                lives--;
                mvprintw(MAP_HEIGHT / 2, (MAP_WIDTH / 2) - 6, "Perdiste una vida");
                refresh();
                sleep(1);
                if (lives <= 0) {
                    *running = false;
                    return;
                }
                reset_positions();
                return;
            }
        }
    }
}

int main(void) {
    setlocale(LC_ALL, ""); // Habilita caracteres extendidos/ACS según la configuración regional
    srand((unsigned int)time(NULL));

    initscr();
    noecho();
    curs_set(FALSE);
    keypad(stdscr, TRUE);
    timeout(180); // Aún más tiempo por tick para girar con comodidad
    init_colors();

    copy_level();
    reset_positions();
    draw_scene();

    bool running = true;
    while (running) {
        int ch = getch();
        if (ch == 'q') {
            break;
        }

        move_pacman(ch);
        move_ghosts();
        handle_collisions(&running);
        draw_scene();
        tick_count++;

        if (dots_left == 0) {
            mvprintw(MAP_HEIGHT / 2, (MAP_WIDTH / 2) - 4, "GANASTE!");
            refresh();
            sleep(2);
            break;
        }
    }

    endwin();
    printf("Juego terminado. Puntuacion final: %d\n", score);
    return 0;
}
// Hola Mundo