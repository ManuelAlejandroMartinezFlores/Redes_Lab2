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


hamming_correct("0110111001", 6, 10)
hamming_correct("0110110001", 6, 10)
hamming_correct("0111111000", 6, 10)


hamming_correct("00110010011", 7, 11)
hamming_correct("00110000011", 7, 11)
hamming_correct("00010010010", 7, 11)


hamming_correct("10110000111", 7, 11)
hamming_correct("10110010111", 7, 11)
hamming_correct("10110000001", 7, 11)


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
    if checksum == (UInt16(sum2) << 8) | sum1
        return code 
    else
        return "Error"
    end
end

check_fletcher8("111101", parse(Int, "1111010011110100", base=2))
check_fletcher8("111111", parse(Int, "1111010011110100", base=2))
check_fletcher8("110111", parse(Int, "1111010011110100", base=2))

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

check_fletcher16("1001011", parse(Int, "10010110000000001001011000000000", base=2))
check_fletcher16("1001111", parse(Int, "10010110000000001001011000000000", base=2))
check_fletcher16("1001111", parse(Int, "10010110000000001011011000000000", base=2))

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

check_fletcher32("1000111", parse(UInt64, "1000111000000000000000000000000010001110000000000000000000000000", base=2))
check_fletcher32("1010111", parse(UInt64, "1000111000000000000000000000000010001110000000000000000000000000", base=2))
check_fletcher32("1010111", parse(UInt64, "1000111000000000000000000000000010001110000000000010000000000000", base=2))


hamming_correct("0"^11, 7, 11)
check_fletcher8("0"^8, 0)