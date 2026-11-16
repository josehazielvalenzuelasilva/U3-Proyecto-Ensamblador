INCLUDE Irvine32.inc

Producto STRUCT
    codigo      BYTE 8 DUP(0)
    nombre      BYTE 26 DUP(0)
    precio      DWORD ?
    existencia  DWORD ?
Producto ENDS

LEER_CADENA MACRO msg, buf, tam
    mov edx, OFFSET msg
    call WriteString
    mov edx, OFFSET buf
    mov ecx, tam
    call ReadString
ENDM

MOSTRAR_ERROR MACRO msg
    mov edx, OFFSET msg
    call WriteString
    call WaitMsg
ENDM

IMPRIMIR_MXN MACRO
    mov edx, OFFSET txtMXN
    call WriteString
ENDM

APLICAR_DESCUENTO MACRO
    mov eax, ebx
    xor edx, edx
    mov edi, 10
    mul edi
    mov edi, 100
    div edi
    sub ebx, eax
ENDM

SIGUIENTE_PRODUCTO MACRO etiq
    LOCAL fin
    add esi, TYPE Producto - 8
    dec ecx
    jnz etiq
    jmp fin
fin:
ENDM

LIMPIAR_BUFFER MACRO buf, tam
    push edi
    push ecx
    mov edi, OFFSET buf
    mov ecx, tam
    xor al, al
    rep stosb
    pop ecx
    pop edi
ENDM

.data
    inventario        Producto 10 DUP(<>)
    contador          DWORD 0
    ingresosTotales   DWORD 0
    cambiosSinGuardar DWORD 0

    bufferCodigo    BYTE 10 DUP(0)
    bufferNombre    BYTE 30 DUP(0)
    bufferPrecio    BYTE 15 DUP(0)
    bufferCantidad  BYTE 10 DUP(0)
    bufferOpcion    BYTE 10 DUP(0)

    menuTxt         BYTE 0Dh, 0Ah, "=== BOUTIQUE ===", 0Dh, 0Ah
                    BYTE "1. Registrar producto", 0Dh, 0Ah
                    BYTE "2. Mostrar inventario", 0Dh, 0Ah
                    BYTE "3. Recibir mercancia", 0Dh, 0Ah
                    BYTE "4. Vender", 0Dh, 0Ah
                    BYTE "5. Mostrar resumen", 0Dh, 0Ah
                    BYTE "6. Guardar catalogo", 0Dh, 0Ah
                    BYTE "7. Cargar catalogo", 0Dh, 0Ah
                    BYTE "8. Salir", 0Dh, 0Ah
                    BYTE "Seleccione una opcion: ", 0

    msgSalir        BYTE "Saliendo. Presione ENTER.", 0
    msgGuardado     BYTE "Catalogo guardado con exito.", 0
    msgCargado      BYTE "Catalogo cargado con exito.", 0
    msgLleno        BYTE "Error: Inventario lleno (Max 10).", 0
    msgDup          BYTE "Error: Codigo duplicado.", 0
    msgErrCodigo    BYTE "Error: Formato de codigo invalido (ABC-123).", 0
    msgErrPrecio    BYTE "Error: Precio invalido (0.01 - 9999.99).", 0
    msgErrCant      BYTE "Error: Cantidad invalida.", 0
    msgErrStock     BYTE "Error: Existencias insuficientes.", 0
    msgNoEncontrado BYTE "Error: Producto no encontrado.", 0
    msgVacio        BYTE "Inventario vacio.", 0
    msgVentaOk      BYTE "Venta realizada.", 0
    msgDescuento    BYTE "Se aplico 10% de descuento por mayoreo.", 0
    msgErrArchivo   BYTE "Error al acceder al archivo.", 0

    msgPromptCod    BYTE "Ingrese codigo (ABC-123): ", 0
    msgPromptNom    BYTE "Ingrese nombre (Max 25): ", 0
    msgPromptPre    BYTE "Ingrese precio (ej. 185.50): ", 0
    msgPromptCant   BYTE "Ingrese cantidad: ", 0

    msgResumenTit   BYTE "=== RESUMEN ===", 0
    msgResumenInv   BYTE "Valor Inventario: ", 0
    msgResumenIng   BYTE "Ingresos Totales: ", 0

    txtMXN          BYTE " MXN", 0
    nombreArchivo   BYTE "inventario.txt", 0
    handleArchivo   DWORD ?
    bytesArchivo    DWORD ?

.code

main PROC
    call Clrscr
menuLoop:
    mov edx, OFFSET menuTxt
    call WriteString
    call LeerOpcion
    cmp al, 1
    je Opcion1
    cmp al, 2
    je Opcion2
    cmp al, 3
    je Opcion3
    cmp al, 4
    je Opcion4
    cmp al, 5
    je Opcion5
    cmp al, 6
    je Opcion6
    cmp al, 7
    je Opcion7
    cmp al, 8
    je Salir
    jmp menuLoop

Opcion1: call RegistrarProducto
    jmp menuLoop
Opcion2: call MostrarInventario
    jmp menuLoop
Opcion3: call RecibirMercancia
    jmp menuLoop
Opcion4: call Vender
    jmp menuLoop
Opcion5: call MostrarResumen
    jmp menuLoop
Opcion6: call GuardarArchivo
    jmp menuLoop
Opcion7: call CargarArchivo
    jmp menuLoop
Salir:
    call Crlf
    mov edx, OFFSET msgSalir
    call WriteString
    call WaitMsg
    exit
main ENDP

LeerOpcion PROC USES ebx ecx edx esi edi
    mov edx, OFFSET bufferOpcion
    mov ecx, SIZEOF bufferOpcion - 1
    call ReadString
    cmp eax, 1
    jne OpcionInvalida
    mov al, [bufferOpcion]
    cmp al, '1'
    jb OpcionInvalida
    cmp al, '8'
    ja OpcionInvalida
    sub al, 30h
    ret
OpcionInvalida:
    xor al, al
    ret
LeerOpcion ENDP

RegistrarProducto PROC USES ebx esi edi ebp
    cmp contador, 10
    jge InvLleno

CapCodigo:
    LIMPIAR_BUFFER bufferCodigo, SIZEOF bufferCodigo
    LEER_CADENA msgPromptCod, bufferCodigo, SIZEOF bufferCodigo - 1
    call ValidarFormatoCodigo
    cmp eax, 0
    je ErrCod
    call BuscarCodigo
    cmp eax, 1
    je ErrCodDup
    jmp CapNombre

ErrCod:
    mov edx, OFFSET msgErrCodigo
    call WriteString
    jmp CapCodigo
ErrCodDup:
    mov edx, OFFSET msgDup
    call WriteString
    jmp CapCodigo

CapNombre:
    LIMPIAR_BUFFER bufferNombre, SIZEOF bufferNombre
    LEER_CADENA msgPromptNom, bufferNombre, 25
    cmp eax, 1
    jl CapNombre

CapPrecio:
    LIMPIAR_BUFFER bufferPrecio, SIZEOF bufferPrecio
    LEER_CADENA msgPromptPre, bufferPrecio, SIZEOF bufferPrecio - 1
    call ConvertirPrecio
    cmp edx, 1
    je ErrPrecio
    cmp eax, 1
    jl ErrPrecio
    cmp eax, 999999
    jg ErrPrecio
    mov ebx, eax
    jmp CapCantidad

ErrPrecio:
    mov edx, OFFSET msgErrPrecio
    call WriteString
    jmp CapPrecio

CapCantidad:
    LIMPIAR_BUFFER bufferCantidad, SIZEOF bufferCantidad
    LEER_CADENA msgPromptCant, bufferCantidad, SIZEOF bufferCantidad - 1
    call ConvertirEntero
    cmp edx, 1
    je ErrCant
    cmp eax, 100
    ja ErrCant
    jmp GuardarProducto

ErrCant:
    mov edx, OFFSET msgErrCant
    call WriteString
    jmp CapCantidad

GuardarProducto:
    mov edx, eax
    mov esi, OFFSET inventario
    mov eax, contador
    imul eax, TYPE Producto
    add esi, eax
    mov ebp, esi
    mov edi, esi
    mov esi, OFFSET bufferCodigo
    call CopiarCampo
    mov esi, OFFSET bufferNombre
    call CopiarCampoNombre
    mov [ebp].Producto.precio, ebx
    mov [ebp].Producto.existencia, edx
    inc contador
    inc cambiosSinGuardar
    jmp FinRegistro

InvLleno:
    MOSTRAR_ERROR msgLleno
FinRegistro:
    ret
RegistrarProducto ENDP

CopiarCampo PROC
    mov ecx, 8
    cld
    rep movsb
    ret
CopiarCampo ENDP

CopiarCampoNombre PROC
    mov ecx, 26
    cld
    rep movsb
    ret
CopiarCampoNombre ENDP

ValidarFormatoCodigo PROC USES esi ecx
    cmp eax, 7
    jne CodMal
    mov esi, OFFSET bufferCodigo
    mov al, [esi]
    cmp al, 'A'
    jb CodMal
    cmp al, 'Z'
    ja CodMal
    mov al, [esi+1]
    cmp al, 'A'
    jb CodMal
    cmp al, 'Z'
    ja CodMal
    mov al, [esi+2]
    cmp al, 'A'
    jb CodMal
    cmp al, 'Z'
    ja CodMal
    cmp byte ptr [esi+3], '-'
    jne CodMal
    mov ecx, 4
ValNum:
    mov al, [esi+ecx]
    cmp al, '0'
    jb CodMal
    cmp al, '9'
    ja CodMal
    inc ecx
    cmp ecx, 7
    jb ValNum
    mov eax, 1
    ret
CodMal:
    xor eax, eax
    ret
ValidarFormatoCodigo ENDP

ConvertirPrecio PROC USES esi ebx ecx ebp edi
    mov esi, OFFSET bufferPrecio
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor ebp, ebp
    xor edi, edi
LoopPre:
    movzx edx, byte ptr [esi]
    cmp edx, 0
    je FinPre
    cmp edx, '.'
    je PuntoPre
    cmp edx, '0'
    jb ErrPre
    cmp edx, '9'
    ja ErrPre
    sub edx, '0'
    cmp ebx, 0
    jne DecimalesPre
    imul ebp, 10
    jo ErrPre
    add ebp, edx
    cmp ebp, 9999
    ja ErrPre
    inc edi
    jmp SigPre
DecimalesPre:
    cmp ecx, 2
    jae ErrPre
    imul eax, 10
    add eax, edx
    inc ecx
SigPre:
    inc esi
    jmp LoopPre
PuntoPre:
    cmp ebx, 1
    je ErrPre
    cmp edi, 0
    je ErrPre
    mov ebx, 1
    jmp SigPre
FinPre:
    cmp edi, 0
    je ErrPre
    cmp ebx, 0
    je EnterosPre
    cmp ecx, 0
    je ErrPre
    cmp ecx, 1
    jne SumarPrecio
    imul eax, 10
SumarPrecio:
    imul ebp, 100
    add eax, ebp
    cmp eax, 999999
    ja ErrPre
    mov edx, 0
    ret
EnterosPre:
    mov eax, ebp
    imul eax, 100
    mov edx, 0
    ret
ErrPre:
    xor eax, eax
    mov edx, 1
    ret
ConvertirPrecio ENDP

ConvertirEntero PROC USES esi ecx
    mov esi, OFFSET bufferCantidad
    xor eax, eax
    xor ecx, ecx
LoopEnt:
    movzx edx, byte ptr [esi]
    cmp edx, 0
    je FinEnt
    cmp edx, '0'
    jb ErrEnt
    cmp edx, '9'
    ja ErrEnt
    sub edx, '0'
    imul eax, 10
    jo ErrEnt
    add eax, edx
    jc ErrEnt
    inc ecx
    inc esi
    jmp LoopEnt
FinEnt:
    cmp ecx, 0
    je ErrEnt
    mov edx, 0
    ret
ErrEnt:
    xor eax, eax
    mov edx, 1
    ret
ConvertirEntero ENDP

BuscarCodigo PROC USES esi edi ecx
    mov esi, OFFSET inventario
    mov ecx, contador
    cmp ecx, 0
    je NoEnc
LoopBus:
    mov edi, OFFSET bufferCodigo
    push ecx
    mov ecx, 8
    cld
    repe cmpsb
    pop ecx
    je SiEnc
    add esi, TYPE Producto - 8
    loop LoopBus
NoEnc:
    xor eax, eax
    ret
SiEnc:
    mov eax, 1
    ret
BuscarCodigo ENDP

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

MostrarInventario PROC USES esi ecx
    cmp contador, 0
    je InvVacio
    mov esi, OFFSET inventario
    mov ecx, contador
LoopMostrar:
    push ecx
    mov edx, esi
    call WriteString
    mov al, ' '
    call WriteChar
    add esi, 8
    mov edx, esi
    call WriteString
    sub esi, 8
    mov al, ' '
    call WriteChar
    mov eax, [esi].Producto.precio
    call MostrarMXN
    mov al, ' '
    call WriteChar
    mov eax, [esi].Producto.existencia
    call WriteDec
    call Crlf
    pop ecx
    add esi, TYPE Producto
    loop LoopMostrar
    jmp FinMost
InvVacio:
    MOSTRAR_ERROR msgVacio
FinMost:
    ret
MostrarInventario ENDP

MostrarMXN PROC USES ebx edx
    mov ebx, 100
    xor edx, edx
    div ebx
    push edx
    call WriteDec
    mov al, '.'
    call WriteChar
    pop eax
    cmp eax, 10
    jae ImprimeCent
    push eax
    mov al, '0'
    call WriteChar
    pop eax
ImprimeCent:
    call WriteDec
    IMPRIMIR_MXN
    ret
MostrarMXN ENDP

RecibirMercancia PROC USES ebx esi
    LIMPIAR_BUFFER bufferCodigo, SIZEOF bufferCodigo
    LEER_CADENA msgPromptCod, bufferCodigo, SIZEOF bufferCodigo - 1
    call BuscarProducto
    cmp eax, 0
    je NoEncontradoRec
    LIMPIAR_BUFFER bufferCantidad, SIZEOF bufferCantidad
    LEER_CADENA msgPromptCant, bufferCantidad, SIZEOF bufferCantidad - 1
    call ConvertirEntero
    cmp edx, 1
    je ErrorCantidadRec
    cmp eax, 0
    je ErrorCantidadRec
    mov ebx, eax
    mov eax, [esi].Producto.existencia
    add eax, ebx
    jc LimitarRec
    cmp eax, 100
    ja LimitarRec
    mov [esi].Producto.existencia, eax
    inc cambiosSinGuardar
    ret
LimitarRec:
    mov [esi].Producto.existencia, 100
    inc cambiosSinGuardar
    ret
ErrorCantidadRec:
    MOSTRAR_ERROR msgErrCant
    ret
NoEncontradoRec:
    MOSTRAR_ERROR msgNoEncontrado
    ret
RecibirMercancia ENDP

Vender PROC USES ebx ecx esi edi
    LIMPIAR_BUFFER bufferCodigo, SIZEOF bufferCodigo
    LEER_CADENA msgPromptCod, bufferCodigo, SIZEOF bufferCodigo - 1
    call BuscarProducto
    cmp eax, 0
    je NoEncontradoVen
    LIMPIAR_BUFFER bufferCantidad, SIZEOF bufferCantidad
    LEER_CADENA msgPromptCant, bufferCantidad, SIZEOF bufferCantidad - 1
    call ConvertirEntero
    cmp edx, 1
    je ErrorCantidadVen
    cmp eax, 0
    je ErrorCantidadVen
    cmp eax, [esi].Producto.existencia
    ja ErrStockVen
    mov ecx, eax
    imul eax, [esi].Producto.precio
    mov ebx, eax
    cmp ecx, 3
    jb SinDescuento
    APLICAR_DESCUENTO
    mov edx, OFFSET msgDescuento
    call WriteString
    call Crlf
SinDescuento:
    mov eax, ebx
    add ingresosTotales, eax
    sub [esi].Producto.existencia, ecx
    inc cambiosSinGuardar
    mov edx, OFFSET msgVentaOk
    call WriteString
    call Crlf
    ret
ErrStockVen:
    MOSTRAR_ERROR msgErrStock
    ret
ErrorCantidadVen:
    MOSTRAR_ERROR msgErrCant
    ret
NoEncontradoVen:
    MOSTRAR_ERROR msgNoEncontrado
    ret
Vender ENDP

MostrarResumen PROC USES esi ecx ebx
    mov edx, OFFSET msgResumenTit
    call WriteString
    call Crlf
    mov edx, OFFSET msgResumenInv
    call WriteString
    mov esi, OFFSET inventario
    mov ecx, contador
    xor ebx, ebx
    cmp ecx, 0
    je FinResumen
LoopRes:
    mov eax, [esi].Producto.precio
    imul eax, [esi].Producto.existencia
    add ebx, eax
    add esi, TYPE Producto
    loop LoopRes
FinResumen:
    mov eax, ebx
    call MostrarMXN
    call Crlf
    mov edx, OFFSET msgResumenIng
    call WriteString
    mov eax, ingresosTotales
    call MostrarMXN
    call Crlf
    call WaitMsg
    ret
MostrarResumen ENDP

GuardarArchivo PROC USES eax
    mov edx, OFFSET nombreArchivo
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je ErrorGuardar
    mov handleArchivo, eax
    mov eax, handleArchivo
    mov edx, OFFSET contador
    mov ecx, 4
    call WriteToFile
    jc ErrorEscritura
    cmp eax, 4
    jne ErrorEscritura
    mov eax, handleArchivo
    mov edx, OFFSET inventario
    mov ecx, SIZEOF inventario
    call WriteToFile
    jc ErrorEscritura
    cmp eax, SIZEOF inventario
    jne ErrorEscritura
    mov eax, handleArchivo
    call CloseFile
    mov cambiosSinGuardar, 0
    mov edx, OFFSET msgGuardado
    call WriteString
    call WaitMsg
    ret
ErrorEscritura:
    mov eax, handleArchivo
    call CloseFile
ErrorGuardar:
    MOSTRAR_ERROR msgErrArchivo
    ret
GuardarArchivo ENDP

CargarArchivo PROC
    mov edx, OFFSET nombreArchivo
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je ErrorCargar
    mov handleArchivo, eax
    mov eax, handleArchivo
    mov edx, OFFSET contador
    mov ecx, 4
    call ReadFromFile
    jc ErrorLectura
    cmp eax, 4
    jne ErrorLectura
    cmp contador, 10
    ja ContadorInvalido
    mov eax, handleArchivo
    mov edx, OFFSET inventario
    mov ecx, SIZEOF inventario
    call ReadFromFile
    jc ErrorLectura
    mov bytesArchivo, eax
    mov eax, handleArchivo
    call CloseFile
    cmp bytesArchivo, SIZEOF inventario
    jne ErrorCargar
    mov cambiosSinGuardar, 0
    mov edx, OFFSET msgCargado
    call WriteString
    call WaitMsg
    ret
ErrorLectura:
    mov eax, handleArchivo
    call CloseFile
    jmp ErrorCargar
ContadorInvalido:
    mov eax, handleArchivo
    call CloseFile
    mov contador, 0
ErrorCargar:
    MOSTRAR_ERROR msgErrArchivo
    ret
CargarArchivo ENDP

END main