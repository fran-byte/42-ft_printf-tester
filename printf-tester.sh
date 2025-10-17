#!/bin/bash

# Modificar extensión a .sh dar permisos y ejecutar ./tester.sh
# Colores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
NC="\033[0m"

# Configuración
TEST_DIR="printf_test"
mkdir -p $TEST_DIR

# Verificar archivos necesarios
echo -e "${BLUE}\nVerificando archivos...${NC}"
REQUIRED_FILES=("ft_printf.c" "ft_printf.h")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: No se encontró $file${NC}"
        exit 1
    fi
done

# COMPILAR AUTOMÁTICAMENTE si no existe libftprintf.a
if [ ! -f "libftprintf.a" ]; then
    echo -e "${YELLOW}Compilando libftprintf.a...${NC}"
    
    # Intentar con make
    if [ -f "Makefile" ]; then
        make
    else
        # Compilación manual si no hay Makefile
        echo -e "${YELLOW}Compilación manual...${NC}"
        cc -Wall -Wextra -Werror -c ft_printf.c
        ar rcs libftprintf.a ft_printf.o
        rm -f ft_printf.o
    fi
    
    # Verificar si se creó la librería
    if [ ! -f "libftprintf.a" ]; then
        echo -e "${RED}Error: No se pudo crear libftprintf.a${NC}"
        exit 1
    fi
    echo -e "${GREEN}libftprintf.a compilado correctamente${NC}"
else
    echo -e "${GREEN}libftprintf.a encontrado${NC}"
fi

# Preparar archivos de prueba
cp ft_printf.c $TEST_DIR/
cp ft_printf.h $TEST_DIR/
cp libftprintf.a $TEST_DIR/


# Crear tester principal 
cat <<EOF > $TEST_DIR/printf_tester.c
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <limits.h>
#include <string.h>
#include "ft_printf.h"

int run_test_case(int test_num __attribute__((unused)), const char* format, ...) {    va_list args1, args2;
    char buffer1[1024];
    char buffer2[1024];

    va_start(args1, format);
    int ft_len = vsprintf(buffer1, format, args1);
    va_end(args1);

    va_start(args2, format);
    int std_len = vsprintf(buffer2, format, args2);
    va_end(args2);

    if (ft_len != std_len) {
        return 1;  // Test fallado
    }

    // Comparación carácter por carácter
    for (int i = 0; i < ft_len; i++) {
        if (buffer1[i] != buffer2[i]) {
            return 1;  // Test fallado
        }
    }

    return 0;  // Test pasado
}



int main() {
    printf("[TEST] Iniciando pruebas...\n");

    int failed = 0;

    // Test 0: String simple
    if (run_test_case(0, "Hola mundo") != 0) failed++;

    // Test 1: Char
    if (run_test_case(1, "%c", 'A') != 0) failed++;

    // Test 2: String
    if (run_test_case(2, "%s", "Hola") != 0) failed++;

    // Test 3: Porcentaje
    if (run_test_case(3, "%%") != 0) failed++;

    // Test 4: Entero
    if (run_test_case(4, "%d", 42) != 0) failed++;

    // Test 5: Entero negativo
    if (run_test_case(5, "%d", -99) != 0) failed++;

    // Test 6: Hexadecimal minúsculas
    if (run_test_case(6, "%x", 255) != 0) failed++;

    // Test 7: Hexadecimal mayúsculas
    if (run_test_case(7, "%X", 255) != 0) failed++;

    // Test 8: Puntero
    int x = 42;
    if (run_test_case(8, "%p", &x) != 0) failed++;

    // Test 9: Combinación
    if (run_test_case(9, "Char: %c, String: %s, Int: %d", 'Z', "Test", 100) != 0) failed++;

    // Test 10: Especiales
    if (run_test_case(10, "Null: %s, Zero: %d", NULL, 0) != 0) failed++;

    // Test 11: INT_MAX
    if (run_test_case(11, "%d", INT_MAX) != 0) failed++;

    // Test 12: INT_MIN
    if (run_test_case(12, "%d", INT_MIN) != 0) failed++;

    // Test 13: String larga
    char long_str[1001];
    memset(long_str, 'A', 1000);
    long_str[1000] = '\\0';
    if (run_test_case(13, "%s", long_str) != 0) failed++;

    // Test 14: 10 parámetros
    if (run_test_case(14, "%d%d%d%d%d%d%d%d%d%d", 1,2,3,4,5,6,7,8,9,10) != 0) failed++;

    if (failed == 0) {
        printf("[TEST] Todos los tests pasaron! 🎉\n");
    } else {
        printf("[TEST] Algunos tests fallaron 😞\n");
    }

    return 0;
}
EOF

# Compilar tester
echo -e "${BLUE}\nCompilando tester...${NC}"
gcc -Wall -Wextra -Werror $TEST_DIR/printf_tester.c -L$TEST_DIR -lftprintf -I$TEST_DIR -o $TEST_DIR/printf_tester 2> $TEST_DIR/compile_errors.log

if [ $? -ne 0 ]; then
    echo -e "${RED}Error en la compilación:${NC}"
    cat $TEST_DIR/compile_errors.log
    exit 1
fi

# Función para ejecutar pruebas
run_test() {
    local test_num=$1
    local description=$2
    local format="$3"
    local expected_len=$4
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    output=$($TEST_DIR/printf_tester "$test_num" "$format")
    
    if [ $? -eq 1 ]; then
        echo -e "${GREEN}[OK]${NC} Test $test_num: $description"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}[KO]${NC} Test $test_num: $description"
        echo -e "${YELLOW}Formato:${NC} \"$format\""
        echo -e "$output"
    fi
}

# Para mostrar el resultado de cada prueba con un resumen al final:

# Inicializar contadores
TOTAL_TESTS=0
PASSED_TESTS=0

# Función para ejecutar pruebas
run_test() {
    local test_num=$1
    local description=$2
    local format="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    output=$($TEST_DIR/printf_tester "$test_num" "$format")
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC} Test $test_num: $description"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}[KO]${NC} Test $test_num: $description"
        echo -e "${YELLOW}Formato:${NC} \"$format\""
        echo -e "$output"
    fi
}

# Tests Básicos
echo -e "${BLUE}\n=== Tests Básicos ===${NC}"

# Test 0: String simple
run_test 0 "String simple" "Hola mundo"

# Test 1: Char
run_test 1 "Char" "%c"

# Test 2: String
run_test 2 "String" "%s"

# Test 3: Porcentaje
run_test 3 "Porcentaje" "%%"

# Test 4: Entero
run_test 4 "Entero" "%d"

# Test 5: Entero negativo
run_test 5 "Entero negativo" "%d"

# Tests Avanzados
echo -e "${MAGENTA}\n=== Tests Avanzados ===${NC}"

# Test 6: Hexadecimal minúsculas
run_test 6 "Hexadecimal minúsculas" "%x"

# Test 7: Hexadecimal mayúsculas
run_test 7 "Hexadecimal mayúsculas" "%X"

# Test 8: Puntero
run_test 8 "Puntero" "%p"

# Test 9: Combinación
run_test 9 "Combinación" "Char: %c, String: %s, Int: %d"

# Test 10: Especiales
run_test 10 "Especiales" "Null: %s, Zero: %d"

# Tests Extremos
echo -e "${RED}\n=== Tests Extremos ===${NC}"

# Test 11: Límites de enteros
run_test 11 "INT_MAX" "%d"

# Test 12: Límites de enteros negativos
run_test 12 "INT_MIN" "%d"

# Test 13: Largo máximo
run_test 13 "String larga" "%s"

# Test 14: Múltiples parámetros
run_test 14 "10 parámetros" "%d%d%d%d%d%d%d%d%d%d"

# Limpieza
rm -rf $TEST_DIR

# Resumen
echo -e "\n${CYAN}=== Resumen Final ===${NC}"
echo -e "Total tests ejecutados: $TOTAL_TESTS"
echo -e "Tests pasados: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Tests fallados: ${RED}$((TOTAL_TESTS - PASSED_TESTS))${NC}"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "\n${GREEN}¡Todos los tests pasaron! 🎉${NC}"
else
    echo -e "\n${RED}Algunos tests fallaron 😞${NC}"
fi
