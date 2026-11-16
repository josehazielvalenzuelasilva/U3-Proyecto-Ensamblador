# Sistema de Inventario y Ventas – Boutique (MASM x86 + Irvine32)

**Materia:** Lenguajes de Interfaz  
**Alumno:** Jose Haziel Valenzuela Silva  
**Horario:** 10:00 – 11:00  
**Docente:** Dr. José Luis Medina Jiménez  
**Actividad:** Proyecto Sistema de Inventario y Ventas (Ropa) – Unidad 3  

---

## Tabla de contenido

1. [Objetivo de la Unidad 3]
2. [Estructura del repositorio]
3. [Ejecución]
4. [Reglas de negocio]
5. [Archivo de inventario]
6. [Versión de la Unidad 3]
   - [6.1 Tabla de antes y después]
   - [6.2 Fragmentos representativos]
   - [6.3 Comparación de líneas de código fuente]
   - [6.4 Documentación de procedimientos]
   - [6.5 Tabla de pruebas actualizada]
7. [Conclusión]

---

## 1. Objetivo de la Unidad 3

Retomar el sistema de la Unidad 2 y mejorar su legibilidad reduciendo el código
repetido mediante **procedimientos**, **macros** y **USES**, conservando todas
las funciones, validaciones y la regla de negocio (descuento del 10% por
mayoreo y tope de 100 unidades en existencia).

---

## 2. Estructura del repositorio

inventario.asm Código fuente completo
inventario.sln Solución de Visual Studio
inventario.vcxproj Proyecto
inventario.txt Inventario de prueba (binario, 424 bytes)
README.md Este archivo (reporte incluido)

---

## 3. Ejecución

Al ejecutar, aparece el menú:
=== BOUTIQUE ===

Registrar producto

Mostrar inventario

Recibir mercancia

Vender

Mostrar resumen

Guardar catalogo

Cargar catalogo

Salir
Seleccione una opcion:

| Opción | Acción | Modifica inventario | Modifica ingresos | Toca disco |
|---|---|---|---|---|
| **1. Registrar** | Crea producto | ✅ Agrega | — | — |
| **2. Mostrar** | Lista productos | ❌ | — | — |
| **3. Recibir** | Suma stock | ✅ Suma (tope 100) | — | — |
| **4. Vender** | Resta stock | ✅ Resta | ✅ Suma | — |
| **5. Resumen** | Muestra totales | ❌ | — | — |
| **6. Guardar** | Escribe archivo | — | — | ✅ Escribe |
| **7. Cargar** | Lee archivo | ✅ Reemplaza | ❌ (se resetean) | ✅ Lee |
| **8. Salir** | Termina | — | — | — |

---

## 4. Reglas de negocio

- Código de producto: formato `ABC-123` (3 letras mayúsculas, guion, 3 dígitos).
- Precio: `0.01` a `9999.99` (se guarda en centavos).
- Existencia: 0 a 100 unidades.
- Máximo 10 productos en inventario.
- **Descuento del 10% por mayoreo** al vender 3 o más unidades del mismo producto.
- **Tope de 100 unidades** al recibir mercancía (si la suma excede 100, se ajusta a 100).

---

## 5. Archivo de inventario

`inventario.txt` es **binario** (no texto legible). Contiene:

- 4 bytes: `contador` (número de productos, DWORD).
- 420 bytes: los 10 registros `Producto` (42 bytes cada uno).

Se genera con la opción **6. Guardar catálogo** y se lee con **7. Cargar catálogo**.
El archivo se crea en el directorio de trabajo del ejecutable (normalmente
`x86\Debug\`).

### Cómo obtener `inventario.txt` para subirlo

1. Compila y ejecuta el programa.
2. Registra al menos 2 productos (opción **1**), por ejemplo:
   - `ABC-123` / `Blusa` / `185.50` / `10`
   - `DEF-456` / `Pantalon` / `350.00` / `5`
3. Ejecuta la opción **6. Guardar catálogo**.
4. Copia el archivo `inventario.txt` desde `x86\Debug\` a la raíz del repositorio.
5. Haz `git add`, `commit` y `push`.

---

## 6. Versión de la Unidad 3

### 6.1 Tabla de antes y después

| Parte del programa | Problema detectado | Cambio aplicado | Beneficio |
|---|---|---|---|
| Captura de datos (6 puntos) | `mov edx,OFFSET msg / call WriteString / mov edx,OFFSET buf / mov ecx,tam / call ReadString` repetido | Macro `LEER_CADENA msg, buf, tam` | 5 instrucciones → 1 línea por captura; menos errores de buffer |
| Mensajes de error (10+ puntos) | `mov edx,OFFSET msg / call WriteString / call WaitMsg` repetido | Macro `MOSTRAR_ERROR msg` | 3 líneas → 1; consistencia visual |
| Búsqueda de producto (3 veces) | `BuscarCodigo` + loop manual `repe cmpsb` repetido en Registrar / Recibir / Vender | Procedimiento `BuscarProducto` que devuelve EAX y **ESI apuntando al registro** | Elimina 3 loops duplicados (~15 líneas c/u) |
| Copia de código/nombre al inventario | `rep movsb` con cálculos repetidos de `imul eax,TYPE Producto` | Procedimientos `CopiarCampo` (8 bytes) y `CopiarCampoNombre` (26 bytes) | Reutilizable; claridad del bloque de guardado |
| Impresión de " MXN" (3 usos) | 6 `WriteChar` por cada letra | Macro `IMPRIMIR_MXN` con `WriteString` | 6 instrucciones → 1 |
| Cálculo de descuento 10% | `mul/div` embebido en `Vender` | Macro `APLICAR_DESCUENTO` | Encapsula la regla de negocio |
| Buffers con basura entre capturas | `ReadString` no borra el buffer; bytes viejos se copiaban al producto | Macro `LIMPIAR_BUFFER buf, tam` | Evita nombres/precios corruptos |
| Precio y existencia en slot equivocado | `rep movsb` avanza EDI; `[edi].Producto.precio` escribía fuera del registro | Guardar base en `EBP` y usar `[ebp].Producto.precio/existencia` | Corrige el bug de `0.00 MXN 0` |
| `MostrarMXN` | Modificaba EBX/EDX sin preservar | `USES ebx edx` | Pila equilibrada; llamada segura |
| `ValidarFormatoCodigo` | Modificaba ESI/ECX | `USES esi ecx` | Sin efectos colaterales |
| `ConvertirPrecio` | Modificaba ESI, EBX, ECX, EBP, EDI | `USES esi ebx ecx ebp edi` | Seguro en cualquier contexto |
| `ConvertirEntero` | Modificaba ESI/ECX | `USES esi ecx` | Seguro |
| `BuscarCodigo` | Modificaba ESI/EDI/ECX | `USES esi edi ecx` | Reutilizable |
| `BuscarProducto` (nuevo) | — | `USES edi ecx`; ESI como salida | Patrón "buscar + apuntar" reutilizable |
| `RegistrarProducto` | Usaba EAX/EBX/ESI/EDI/EBP de forma global | `USES ebx esi edi ebp` | Protege registros del llamador |
| `Vender` | Usaba EBX/ECX/ESI/EDI | `USES ebx ecx esi edi` | Protege registros |
| `MostrarResumen` | Usaba ESI/ECX/EBX | `USES esi ecx ebx` | Protege registros |
| Macro con etiqueta interna | Riesgo de colisión si se usa 2+ veces | `SIGUIENTE_PRODUCTO` con `LOCAL fin` | Evita errores de ensamblado |
| `MostrarInventario` | Nombre y precio pegados (`Calzon35.00 MXN1`) | Espacio entre nombre, precio y existencia | Salida legible: `Calzon 35.00 MXN 1` |

**Criterio de elección macro vs. procedimiento**

- **Macro:** secuencias cortas, fijas y sin lógica de control de flujo
  (`LEER_CADENA`, `MOSTRAR_ERROR`, `IMPRIMIR_MXN`, `APLICAR_DESCUENTO`,
  `LIMPIAR_BUFFER`, `SIGUIENTE_PRODUCTO`). El ahorro es directo en el `.asm`
  y MASM las expande en cada uso.
- **Procedimiento:** tareas con retorno de valor, control de flujo o
  reutilización con estado (`BuscarProducto`, `BuscarCodigo`,
  `ConvertirPrecio`, `ConvertirEntero`, `ValidarFormatoCodigo`,
  `CopiarCampo`, `CopiarCampoNombre`, `MostrarMXN`). Requieren `ret` y
  manejo de pila.

### 6.2 Fragmentos representativos

#### (a) Procedimiento reutilizado – `BuscarProducto`
**Archivo:** `inventario.asm`

```asm
; Busca el producto y deja ESI apuntando a él si existe.
; Recibe: bufferCodigo (global) y contador (global).
; Devuelve: EAX = 1 encontrado / 0 no; ESI = dirección del producto.
; USES preserva EDI y ECX; ESI es salida intencional.
BuscarProducto PROC USES edi ecx
    mov esi, OFFSET inventario
    mov ecx, contador
    cmp ecx, 0
    je NoEncontrado
LoopBus:
    mov edi, OFFSET bufferCodigo
    push ecx
    mov ecx, 8
    cld
    repe cmpsb
    pop ecx
    je Encontrado
    add esi, TYPE Producto - 8
    loop LoopBus
NoEncontrado:
    xor eax, eax
    ret
Encontrado:
    mov eax, 1
    ret
BuscarProducto ENDP
Puntos de uso (3): RecibirMercancia, Vender y cualquier búsqueda futura.

asm
call BuscarProducto
cmp eax, 0
je NoEncontradoRec   ; o NoEncontradoVen
; ESI ya apunta al producto
(b) Macro LEER_CADENA y sus puntos de uso
Archivo: inventario.asm

asm
LEER_CADENA MACRO msg, buf, tam
    mov edx, OFFSET msg
    call WriteString
    mov edx, OFFSET buf
    mov ecx, tam
    call ReadString
ENDM
Usos (6):

asm
LEER_CADENA msgPromptCod,  bufferCodigo,   SIZEOF bufferCodigo - 1
LEER_CADENA msgPromptNom,  bufferNombre,   25
LEER_CADENA msgPromptPre,  bufferPrecio,   SIZEOF bufferPrecio - 1
LEER_CADENA msgPromptCant, bufferCantidad, SIZEOF bufferCantidad - 1
; repetido en RecibirMercancia y Vender
(c) Procedimiento con USES – ConvertirPrecio
Archivo: inventario.asm

asm
; Recibe: bufferPrecio (global) con la cadena.
; Devuelve: EAX = centavos, EDX = 0 OK / 1 error.
; USES preserva ESI, EBX, ECX, EBP, EDI.
; EAX y EDX quedan FUERA de USES porque son salida.
ConvertirPrecio PROC USES esi ebx ecx ebp edi
    mov esi, OFFSET bufferPrecio
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor ebp, ebp
    xor edi, edi
    ; ... lógica de conversión ...
    ret
ConvertirPrecio ENDP
(d) Macro con LOCAL – SIGUIENTE_PRODUCTO
asm
SIGUIENTE_PRODUCTO MACRO etiq
    LOCAL fin
    add esi, TYPE Producto - 8
    dec ecx
    jnz etiq
    jmp fin
fin:
ENDM
LOCAL fin evita símbolo duplicado si la macro se expande en varios puntos.

6.3 Comparación de líneas de código fuente
Criterio: se cuentan líneas de instrucciones y directivas de código
(PROC/ENDP, MACRO/ENDM, instrucciones, etiquetas), sin contar
líneas en blanco, comentarios ni el bloque .data de mensajes. Mismo
criterio en ambas versiones.

Versión	Líneas de código	Observación
Unidad 2 (original)	~340	Búsqueda y captura duplicadas en 3 módulos
Unidad 3 (refactorizada)	~285	Se eliminaron bloques repetidos
Bloques que dejaron de repetirse:

Captura WriteString + ReadString: aparecía 6 veces → 1 macro con 6 usos.

Búsqueda repe cmpsb: aparecía 3 veces → 1 procedimiento con 3 llamadas.

Bloque de error WriteString + WaitMsg: aparecía 10+ veces → 1 macro.

Impresión " MXN": aparecía 3 veces con 6 WriteChar → 1 macro.

Cálculo del descuento por mayoreo: embebido en Vender → 1 macro.

Limpieza de buffers: no existía → 1 macro usada en 8 puntos.

Nota: una macro reduce la repetición en el archivo .asm, pero MASM
expande sus instrucciones en cada punto de uso. El ahorro es de
legibilidad y mantenimiento, no de tamaño del binario.

6.4 Documentación de procedimientos
Procedimiento	Recibe	Devuelve	Registros que preserva (USES)	Registros de salida
LeerOpcion	bufferOpcion	AL = dígito 1..8 o 0	EBX, ECX, EDX, ESI, EDI	AL
RegistrarProducto	buffers globales	—	EBX, ESI, EDI, EBP	—
CopiarCampo	ESI, EDI	ESI/EDI avanzados	— (no aplica)	ESI, EDI, ECX
CopiarCampoNombre	ESI, EDI	ESI/EDI avanzados	— (no aplica)	ESI, EDI, ECX
ValidarFormatoCodigo	bufferCodigo	EAX = 1/0	ESI, ECX	EAX
ConvertirPrecio	bufferPrecio	EAX = centavos, EDX = 0/1	ESI, EBX, ECX, EBP, EDI	EAX, EDX
ConvertirEntero	bufferCantidad	EAX = valor, EDX = 0/1	ESI, ECX	EAX, EDX
BuscarCodigo	bufferCodigo	EAX = 1/0	ESI, EDI, ECX	EAX
BuscarProducto	bufferCodigo	EAX = 1/0, ESI = producto	EDI, ECX	EAX, ESI
MostrarInventario	inventario, contador	—	ESI, ECX	—
MostrarMXN	EAX = centavos	—	EBX, EDX	—
RecibirMercancia	bufferCodigo, bufferCantidad	—	EBX, ESI	—
Vender	bufferCodigo, bufferCantidad	—	EBX, ECX, ESI, EDI	—
MostrarResumen	inventario, contador	—	ESI, ECX, EBX	—
GuardarArchivo	inventario, contador	—	EAX	—
CargarArchivo	inventario.txt	—	—	—
Verificación de pila: todos los procedimientos con USES balancean
la pila porque MASM inserta los push al entrar y los pop al salir. Los
registros de salida (EAX, EDX, ESI según el caso) quedan fuera de USES.

6.5 Tabla de pruebas actualizada
#	Entrada	Resultado esperado	Resultado obtenido
1	Registrar ABC-123, Blusa, 185.50, 10	Producto agregado, contador=1	 Producto agregado, contador=1
2	Registrar código AB-123	Error formato, reintenta código	 Mensaje y reintento
3	Registrar código duplicado ABC-123	Error código duplicado	 Mensaje y reintento
4	Registrar precio 0	Error precio inválido	 Mensaje y reintento
5	Registrar precio 10000.00	Error precio inválido (>9999.99)	 Mensaje y reintento
6	Registrar cantidad 150	Error cantidad inválida (>100)	 Mensaje y reintento
7	Registrar 11.º producto	Error inventario lleno	 Mensaje de lleno
8	Registrar nombre corto y luego largo	Nombre correcto, sin basura	 Sin residuos del buffer anterior
9	Recibir mercancía ABC-123 cantidad 5	Existencia 10 → 15	 Existencia actualizada
10	Recibir mercancía ABC-123 cantidad 95	Existencia limitada a 100	 Existencia = 100
11	Recibir mercancía código inexistente	Error no encontrado	 Mensaje
12	Vender ABC-123 cantidad 2	Venta sin descuento	 Venta sin descuento
13	Vender ABC-123 cantidad 3	Descuento 10%	 Mensaje descuento y venta
14	Vender cantidad > existencia	Error stock insuficiente	 Mensaje de stock
15	Vender código inexistente	Error no encontrado	 Mensaje
16	Mostrar inventario	ABC-124 Calzon 35.00 MXN 1 con espacios	 Formato legible
17	Mostrar resumen con inventario	Valor inventario e ingresos en MXN	 Cifras correctas
18	Guardar catálogo	Archivo inventario.txt de 424 bytes	 Archivo generado
19	Cargar catálogo guardado	Inventario restaurado	 Datos restaurados
20	Cargar archivo inexistente	Error de archivo	 Mensaje
21	Cargar archivo con contador > 10	Error, contador = 0	 Validación aplicada
22	Salir del menú	Mensaje de despedida	 Sale correctamente
Regla adicional del negocio probada: descuento del 10% por mayoreo
(cantidad ≥ 3) — prueba #13 .


- 420 bytes: los 10 registros `Producto` (42 bytes cada uno).

Se genera con la opción **6. Guardar catálogo** y se lee con **7. Cargar catálogo**.
El archivo se crea en el directorio de trabajo del ejecutable (normalmente
`x86\Debug\`).

7. Conclusión
La refactorización de la Unidad 3 reduce la repetición, mejora la legibilidad
y corrige dos bugs de la Unidad 2 (buffers con basura y escritura de
precio/existencia fuera del registro). Se conservaron todas las funciones,
validaciones y la regla de negocio original (descuento 10% por mayoreo, tope
de 100 unidades, máximo 10 productos, formato ABC-123, precio
0.01–9999.99). El sistema queda listo para mantenimiento y ampliación.
