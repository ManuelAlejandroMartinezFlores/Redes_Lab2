# Helper function: Check if a number is a power of 2
ispow2(x) = x > 0 && (x & (x - 1)) == 0

# Find all parity bit positions in an n-bit codeword
function get_parity_positions(n)
    parity_pos = Int[]
    pos = 1
    while pos <= n
        push!(parity_pos, pos)
        pos <<= 1  # Multiply by 2
    end
    return parity_pos
end


function hamming_correct(processed_msg::String, m::Int, n::Int)
    @assert length(processed_msg) == n "Processed message must be length $n"
    
    parity_pos = get_parity_positions(n)
    codeword = []
    for i in 1:n
        if i in parity_pos
            continue
        end 
        push!(codeword, parse(Int, processed_msg[i]))
    end
    syndrome = 0
    
    # Compute syndrome
    for p in parity_pos
        sum_parity = parse(Int, processed_msg[p])
        for i in 1:m
            if (i & p) != 0  # All bits covered by this parity
                sum_parity += codeword[i]
            end
        end
        if sum_parity % 2 != 0
            syndrome += p
        end
    end
    
    # Correct error if found
    if syndrome != 0
        if syndrome <= m
            codeword[syndrome] = 1 - codeword[syndrome]
        end
        corrected = join(codeword)
        return (corrected = corrected, error_pos = syndrome)
    else
        return (corrected = join(codeword), error_pos = nothing)
    end
end



function check_fletcher8(code, checksum)
    pad_len = mod(8 - mod(length(code), 8), 8)
    code = code * "0" ^ pad_len
    words = [parse(UInt8, code[i:i+7], base=2) for i in 1:8:length(code)]
    sum1 = 0
    sum2 = 0
    for w in words
        sum1 = (sum1 + w) % 255
        sum2 = (sum2 + sum1) % 255 
    end
    if checksum == string(sum1, base=2, pad=8) * string(sum2, base=2, pad=8) 
        return code 
    else
        return "Error"
    end
end

function check_fletcher16(code, checksum)
    pad_len = mod(16 - mod(length(code), 16), 16)
    code = code * "0" ^ pad_len
    words = [parse(UInt16, code[i:i+15], base=2) for i in 1:16:length(code)]
    sum1 = 0x0000
    sum2 = 0x0000
    for w in words
        sum1 = (sum1 + w) % 65535
        sum2 = (sum2 + sum1) % 65535 
    end
    if checksum == (UInt32(sum2) << 16) | sum1
        return code 
    else
        return "Error"
    end
end

function check_fletcher32(code, checksum)
    pad_len = mod(32 - mod(length(code), 32), 32)
    code = code * "0" ^ pad_len
    words = [parse(UInt32, code[i:i+31], base=2) for i in 1:32:length(code)]
    sum1 = 0x00000000
    sum2 = 0x00000000
    for w in words
        sum1 = (sum1 + w) % 0xFFFFFFFF
        sum2 = (sum2 + sum1) % 0xFFFFFFFF 
    end
    if checksum == (UInt64(sum2) << 32) | sum1
        return code 
    else
        return "Error"
    end
end

function binary_to_string(binary_str::String, method::String)::String
    # Check if the binary string length is a multiple of 8
    

    message = ""
    if method == "hamming"
        if length(binary_str) % 12 != 0
            error("Binary string length must be divisible by 8 (each ASCII char is 8 bits).")
        end
        # Iterate over each 8-bit segment
        for i in 1:12:length(binary_str)
            byte = binary_str[i:i+11]  # Extract 8 bits
            result = hamming_correct(byte, 8, 12)
            if result.error_pos !== nothing
                # return "Error"
            end
            char = Char(parse(Int, result.corrected, base=2))  # Convert to ASCII character
            message *= char
        end
    else 
        checksum = binary_str[end-15:end]
        if check_fletcher8(binary_str[1:end-16], checksum) == "Error"
            return "Error"
        end
        for i in 1:8:length(binary_str[1:end-16])
            byte = binary_str[i:i+7]
            char = Char(parse(Int, byte, base=2))
            message *= char
        end
    end
    return message
end


using Sockets

base_msg = "abcdefghijklmnopqrstuvwxyz"
k = 1

# Start a server listening on port 8080
server = listen(8080)
println("Esperando a Python ...")
conn = accept(server)


# Accept a connection


results = []

for k in [1, 2, 4]
    for p in [1e-3, 1e-2, 1e-1]
        for m in ["0", "1"]
            cnt = 0 
            correct = 0 
            msg = "abcdefghijklmnopqrstuvwxyz" ^ k
            data = readavailable(conn)  # Read raw bytes
            decoded_message = String(data) 
            for w in split(decoded_message, " ")
                if w[1] == '0'
                    method = "hamming"
                else 
                    method = "fletcher"
                end
                decoded = binary_to_string(String(w[2:end]), method)
                if m == "1" && (decoded == "Error" || decoded == msg)
                    correct += 1
                end 
                if m == "0" && decoded == msg
                    correct += 1 
                end
                cnt += 1
            end
            push!(results, correct / cnt)
        end
    end
end

println(join(results, "\n"))

