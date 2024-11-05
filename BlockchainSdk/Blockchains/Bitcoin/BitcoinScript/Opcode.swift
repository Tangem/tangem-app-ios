//
//  OpCode.swift
//
//  Copyright © 2018 BitcoinKit developers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

enum OpCode: OpCodeProtocol {
    // swiftlint:disable:next line_length
    case OP_0
    case OP_FALSE
    case OP_PUSHDATA1
    case OP_PUSHDATA2
    case OP_PUSHDATA4
    case OP_1NEGATE
    case OP_RESERVED
    case OP_1
    case OP_TRUE
    case OP_2
    case OP_3
    case OP_4
    case OP_5
    case OP_6
    case OP_7
    case OP_8
    case OP_9
    case OP_10
    case OP_11
    case OP_12
    case OP_13
    case OP_14
    case OP_15
    case OP_16
    case OP_NOP
    case OP_VER
    case OP_IF
    case OP_NOTIF
    case OP_VERIF
    case OP_VERNOTIF
    case OP_ELSE
    case OP_ENDIF
    case OP_VERIFY
    case OP_RETURN
    case OP_TOALTSTACK
    case OP_FROMALTSTACK
    case OP_2DROP
    case OP_2DUP
    case OP_3DUP
    case OP_2OVER
    case OP_2ROT
    case OP_2SWAP
    case OP_IFDUP
    case OP_DEPTH
    case OP_DROP
    case OP_DUP
    case OP_NIP
    case OP_OVER
    case OP_PICK
    case OP_ROLL
    case OP_ROT
    case OP_SWAP
    case OP_TUCK
    case OP_CAT
    case OP_SIZE
    case OP_SPLIT
    case OP_NUM2BIN
    case OP_BIN2NUM
    case OP_INVERT
    case OP_AND
    case OP_OR
    case OP_XOR
    case OP_EQUAL
    case OP_EQUALVERIFY
    case OP_RESERVED1
    case OP_RESERVED2
    case OP_1ADD
    case OP_1SUB
    case OP_2MUL
    case OP_2DIV
    case OP_NEGATE
    case OP_ABS
    case OP_NOT
    case OP_0NOTEQUAL
    case OP_ADD
    case OP_SUB
    case OP_MUL
    case OP_DIV
    case OP_MOD
    case OP_LSHIFT
    case OP_RSHIFT
    case OP_BOOLAND
    case OP_BOOLOR
    case OP_NUMEQUAL
    case OP_NUMEQUALVERIFY
    case OP_NUMNOTEQUAL
    case OP_LESSTHAN
    case OP_GREATERTHAN
    case OP_LESSTHANOREQUAL
    case OP_GREATERTHANOREQUAL
    case OP_MIN
    case OP_MAX
    case OP_WITHIN
    case OP_RIPEMD160
    case OP_SHA1
    case OP_SHA256
    case OP_HASH160
    case OP_HASH256
    case OP_CODESEPARATOR
    case OP_CHECKSIG
    case OP_CHECKSIGVERIFY
    case OP_CHECKMULTISIG
    case OP_CHECKMULTISIGVERIFY
    case OP_CHECKLOCKTIMEVERIFY
    case OP_CHECKSEQUENCEVERIFY
    case OP_PUBKEYHASH
    case OP_PUBKEY
    case OP_INVALIDOPCODE
    case OP_NOP1
    case OP_NOP4
    case OP_NOP5
    case OP_NOP6
    case OP_NOP7
    case OP_NOP8
    case OP_NOP9
    case OP_NOP10

    private var opcode: OpCodeProtocol {
        switch self {
        // 1. Operators pushing data on stack.
        case .OP_0: return Op0()
        case .OP_FALSE: return OpCode.OP_0.opcode
        case .OP_PUSHDATA1: return OpPushData1()
        case .OP_PUSHDATA2: return OpPushData2()
        case .OP_PUSHDATA4: return OpPushData4()
        case .OP_1NEGATE: return Op1Negate()
        case .OP_RESERVED: return OpReserved() // reserved and fail if executed
        case .OP_1: return OpN(1)
        case .OP_TRUE: return OpCode.OP_1.opcode
        case .OP_2: return OpN(2)
        case .OP_3: return OpN(3)
        case .OP_4: return OpN(4)
        case .OP_5: return OpN(5)
        case .OP_6: return OpN(6)
        case .OP_7: return OpN(7)
        case .OP_8: return OpN(8)
        case .OP_9: return OpN(9)
        case .OP_10: return OpN(10)
        case .OP_11: return OpN(11)
        case .OP_12: return OpN(12)
        case .OP_13: return OpN(13)
        case .OP_14: return OpN(14)
        case .OP_15: return OpN(15)
        case .OP_16: return OpN(16)

        // 2. Flow Control operators
        case .OP_NOP: return OpNop()
        case .OP_VER: return OpVer()
        case .OP_IF: return OpIf()
        case .OP_NOTIF: return OpNotIf()
        case .OP_VERIF: return OpVerIf()
        case .OP_VERNOTIF: return OpVerNotIf()
        case .OP_ELSE: return OpElse()
        case .OP_ENDIF: return OpEndIf()
        case .OP_VERIFY: return OpVerify()
        case .OP_RETURN: return OpReturn()

        // 3. Stack ops
        case .OP_TOALTSTACK: return OpToAltStack()
        case .OP_FROMALTSTACK: return OpFromAltStack()
        case .OP_2DROP: return Op2Drop()
        case .OP_2DUP: return Op2Duplicate()
        case .OP_3DUP: return Op3Duplicate()
        case .OP_2OVER: return Op2Over()
        case .OP_2ROT: return Op2Rot()
        case .OP_2SWAP: return Op2Swap()
        case .OP_IFDUP: return OpIfDup()
        case .OP_DEPTH: return OpDepth()
        case .OP_DROP: return OpDrop()
        case .OP_DUP: return OpDuplicate()
        case .OP_NIP: return OpNip()
        case .OP_OVER: return OpOver()
        case .OP_PICK: return OpPick()
        case .OP_ROLL: return OpRoll()
        case .OP_ROT: return OpRot()
        case .OP_SWAP: return OpSwap()
        case .OP_TUCK: return OpTuck()

        // 4. Splice ops
        case .OP_CAT: return OpConcatenate()
        case .OP_SIZE: return OpSize()
        case .OP_SPLIT: return OpSplit()
        case .OP_NUM2BIN: return OpExample()
        case .OP_BIN2NUM: return OpExample()

        // 5. Bitwise logic
        case .OP_INVERT: return OpInvert()
        case .OP_AND: return OpAnd()
        case .OP_OR: return OpOr()
        case .OP_XOR: return OpXor()
        case .OP_EQUAL: return OpEqual()
        case .OP_EQUALVERIFY: return OpEqualVerify()
        case .OP_RESERVED1: return OpReserved1() // reserved and fail if executed
        case .OP_RESERVED2: return OpReserved2() // reserved and fail if executed

        // 6. Arithmetic
        case .OP_1ADD: return Op1Add()
        case .OP_1SUB: return Op1Sub()
        case .OP_2MUL: return Op2Mul()
        case .OP_2DIV: return Op2Div()
        case .OP_NEGATE: return OpNegate()
        case .OP_ABS: return OpAbsolute()
        case .OP_NOT: return OpNot()
        case .OP_0NOTEQUAL: return OP0NotEqual()
        case .OP_ADD: return OpAdd()
        case .OP_SUB: return OpSub()
        case .OP_MUL: return OpMul()
        case .OP_DIV: return OpDiv()
        case .OP_MOD: return OpMod()
        case .OP_LSHIFT: return OpLShift()
        case .OP_RSHIFT: return OpRShift()
        case .OP_BOOLAND: return OpBoolAnd()
        case .OP_BOOLOR: return OpBoolOr()
        case .OP_NUMEQUAL: return OpNumEqual()
        case .OP_NUMEQUALVERIFY: return OpNumEqualVerify()
        case .OP_NUMNOTEQUAL: return OpNumNotEqual()
        case .OP_LESSTHAN: return OpLessThan()
        case .OP_GREATERTHAN: return OpGreaterThan()
        case .OP_LESSTHANOREQUAL: return OpLessThanOrEqual()
        case .OP_GREATERTHANOREQUAL: return OpGreaterThanOrEqual()
        case .OP_MIN: return OpMin()
        case .OP_MAX: return OpMax()
        case .OP_WITHIN: return OpWithin()

        // Crypto
        case .OP_RIPEMD160: return OpRipemd160()
        case .OP_SHA1: return OpSha1()
        case .OP_SHA256: return OpSha256()
        case .OP_HASH160: return OpHash160()
        case .OP_HASH256: return OpHash256()
        case .OP_CODESEPARATOR: return OpCodeSeparator()
        case .OP_CHECKSIG: return OpCheckSig()
        case .OP_CHECKSIGVERIFY: return OpCheckSigVerify()
        case .OP_CHECKMULTISIG: return OpCheckMultiSig()
        case .OP_CHECKMULTISIGVERIFY: return OpCheckMultiSigVerify()

        // Lock Times
        case .OP_CHECKLOCKTIMEVERIFY: return OpCheckLockTimeVerify() // previously OP_NOP2
        case .OP_CHECKSEQUENCEVERIFY: return OpCheckSequenceVerify() // previously OP_NOP3

        // Pseudo Words
        case .OP_PUBKEYHASH: return OpPubkeyHash()
        case .OP_PUBKEY: return OpPubkey()
        case .OP_INVALIDOPCODE: return OpInvalidOpCode()

        // Reserved Words
        case .OP_NOP1: return OpNop1()
        case .OP_NOP4: return OpNop4()
        case .OP_NOP5: return OpNop5()
        case .OP_NOP6: return OpNop6()
        case .OP_NOP7: return OpNop7()
        case .OP_NOP8: return OpNop8()
        case .OP_NOP9: return OpNop9()
        case .OP_NOP10: return OpNop10()
        }
    }

    // swiftlint:disable:next line_length
    internal static let list: [OpCode] = [OP_0, OP_FALSE, OP_PUSHDATA1, OP_PUSHDATA2, OP_PUSHDATA4, OP_1NEGATE, OP_RESERVED, OP_1, OP_TRUE, OP_2, OP_3, OP_4, OP_5, OP_6, OP_7, OP_8, OP_9, OP_10, OP_11, OP_12, OP_13, OP_14, OP_15, OP_16, OP_NOP, OP_VER, OP_IF, OP_NOTIF, OP_VERIF, OP_VERNOTIF, OP_ELSE, OP_ENDIF, OP_VERIFY, OP_RETURN, OP_TOALTSTACK, OP_FROMALTSTACK, OP_2DROP, OP_2DUP, OP_3DUP, OP_2OVER, OP_2ROT, OP_2SWAP, OP_IFDUP, OP_DEPTH, OP_DROP, OP_DUP, OP_NIP, OP_OVER, OP_PICK, OP_ROLL, OP_ROT, OP_SWAP, OP_TUCK, OP_CAT, OP_SIZE, OP_SPLIT, OP_NUM2BIN, OP_INVERT, OP_AND, OP_OR, OP_XOR, OP_EQUAL, OP_EQUALVERIFY, OP_RESERVED1, OP_RESERVED2, OP_BIN2NUM, OP_1ADD, OP_1SUB, OP_2MUL, OP_2DIV, OP_NEGATE, OP_ABS, OP_NOT, OP_0NOTEQUAL, OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_MOD, OP_LSHIFT, OP_RSHIFT, OP_BOOLAND, OP_BOOLOR, OP_NUMEQUAL, OP_NUMEQUALVERIFY, OP_NUMNOTEQUAL, OP_LESSTHAN, OP_GREATERTHAN, OP_LESSTHANOREQUAL, OP_GREATERTHANOREQUAL, OP_MIN, OP_MAX, OP_WITHIN, OP_RIPEMD160, OP_SHA1, OP_SHA256, OP_HASH160, OP_HASH256, OP_CODESEPARATOR, OP_CHECKSIG, OP_CHECKSIGVERIFY, OP_CHECKMULTISIG, OP_CHECKMULTISIGVERIFY, OP_CHECKLOCKTIMEVERIFY, OP_CHECKSEQUENCEVERIFY, OP_PUBKEYHASH, OP_PUBKEY, OP_INVALIDOPCODE, OP_NOP1, OP_NOP4, OP_NOP5, OP_NOP6, OP_NOP7, OP_NOP8, OP_NOP9, OP_NOP10]

    var name: String {
        return opcode.name
    }

    var value: UInt8 {
        return opcode.value
    }

    var isOpCode: Bool {
        self > OpCode.OP_PUSHDATA4
    }
}
