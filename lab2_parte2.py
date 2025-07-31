#Emisor código de Hamming

def posiciones_paridad(n):
    i = 1
    pos = []
    while i <= n:
        pos.append(i)
        i *= 2
    return pos

def hamming_codificar(mensaje):
    m = len(mensaje)
    
    r = 0
    while (2 ** r) < (m + r + 1):
        r += 1

    n = m + r
    par_pos = posiciones_paridad(n)

    codigo = [0] * (n + 1)  
    data_bits = [int(c) for c in mensaje]
    msg_index = 0
    pos = 1
    data_pos_map = {}  

    for i in range(1, n + 1):
        if i not in par_pos:
            codigo[i] = data_bits[msg_index]
            data_pos_map[pos] = i
            pos += 1
            msg_index += 1

    for p in par_pos:
        suma = 0
        for logical_idx in range(1, m + 1):
            if logical_idx & p:
                codigo[p] += codigo[data_pos_map[logical_idx]]
        codigo[p] = codigo[p] % 2

    return ''.join(str(codigo[i]) for i in range(1, n + 1))

# Emisor código Fletcher Checksum

def dividir_en_bloques(data_binaria, bloque_bits):
    padding = (-len(data_binaria)) % bloque_bits
    data_binaria += '0' * padding

    bloques = [data_binaria[i:i + bloque_bits] for i in range(0, len(data_binaria), bloque_bits)]
    return bloques

def fletcher_checksum_bloques(data_binaria, bloque_bits=8):

    if bloque_bits not in [8, 16, 32]:
        raise ValueError("El tamaño de bloque debe ser 8, 16 o 32 bits")

    bloques = dividir_en_bloques(data_binaria, bloque_bits)
    sum1 = 0
    sum2 = 0
    mod = 2 ** bloque_bits - 1 

    for bloque in bloques:
        valor = int(bloque, 2)
        sum1 = (sum1 + valor) % mod
        sum2 = (sum2 + sum1) % mod

    checksum1 = format(sum1, f'0{bloque_bits}b')
    checksum2 = format(sum2, f'0{bloque_bits}b')

    checksum_total = checksum1 + checksum2
    mensaje_codificado = data_binaria + checksum_total

    return {
        "mensaje_original": data_binaria,
        "checksum": checksum_total,
        "mensaje_codificado": mensaje_codificado
    }

import random

def ruido(cadena, probabilidad=0.001):
    lista = list(cadena)
    for i in range(len(lista)):
        if random.random() < probabilidad:
            lista[i] = '1' if lista[i] == '0' else '0'
    return ''.join(lista)

def string_to_binary(message: str, method) -> str:
    """Encodes each character in a string to its 8-bit ASCII binary representation.
    
    Args:
        message: Input string to encode.
    
    Returns:
        A string of '0's and '1's where each 8-bit segment represents a character.
    """
    binary_str = ""
    for char in message:
        # Get ASCII value, then convert to 8-bit binary (zero-padded)
        binary_char = bin(ord(char))[2:].zfill(8)
        if method == "hamming":
            binary_str += hamming_codificar(binary_char)
        else:
            binary_str += binary_char
    if method == "hamming":
        return binary_str
    else:
        return fletcher_checksum_bloques(binary_str)["mensaje_codificado"] 

import socket 


if __name__ == "__main__":
    while True:
        msg = input("Ingresar mensaje: ")
        if msg =="": 
            break
        method = input("0: hamming\n1: fletcher\n")
        m = "hamming" if method == "0" else "fletcher"
        encoded_message = str.encode(method + ruido(string_to_binary(msg, m), probabilidad=0.01))
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect(("localhost", 8080))  # Julia server address
            s.sendall(encoded_message)
            print(f"Enviado a Julia")

