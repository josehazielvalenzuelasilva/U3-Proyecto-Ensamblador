# Reporte – Sistema de Inventario y Ventas (Boutique)
## Unidad 3: Procedimientos, Macros y USES

**Materia:** Lenguajes de Interfaz  
**Alumno:** Jose Haziel Valenzuela Silva  
**Horario:** 10:00 – 11:00  
**Docente:** Dr. José Luis Medina Jiménez  
**Actividad:** Proyecto Sistema de Inventario y Ventas (Ropa) – Unidad 3  

---

## 1. Objetivo de la Unidad 3

Retomar el sistema de la Unidad 2 y mejorar su legibilidad reduciendo el código
repetido mediante **procedimientos**, **macros** y **USES**, conservando todas
las funciones, validaciones y la regla de negocio (descuento del 10% por
mayoreo y tope de 100 unidades en existencia).

---

## 2. Versión de la Unidad 3

### 2.1 Tabla de antes y después

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
