//
//  CapertSerializationTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Skibin on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import XCTest
@testable import BlockchainSdk

final class CapertSerializationTests: XCTestCase {
    func testAll() {
        // Test 1: deploy header serialization test
        let deployHeader = DeployHeader()
        deployHeader.account = "01d9bf2148748a85c89da5aad8ee0b0fc2d105fd39d41a4c796536354f0ae2900c"
        deployHeader.timestamp = "2020-11-17T00:39:24.072Z"
        deployHeader.ttl = "1h"
        deployHeader.gasPrice = 1
        // "19ead6b04eab817745a9c9860a395d45d34200a0a52e7bbab098ec6c6e0d5970"
        deployHeader.bodyHash = "4811966d37fe5674a8af4001884ea0d9042d1c06668da0c963769c3a01ebd08f"
        deployHeader.dependencies = ["0101010101010101010101010101010101010101010101010101010101010101"]
        deployHeader.chainName = "casper-example"
        let headerSerialization = DeployHeaderSerialization.serialize(from: deployHeader)
        XCTAssert(headerSerialization == "01d9bf2148748a85c89da5aad8ee0b0fc2d105fd39d41a4c796536354f0ae2900ca856a4d37501000080ee36000000000001000000000000004811966d37fe5674a8af4001884ea0d9042d1c06668da0c963769c3a01ebd08f0100000001010101010101010101010101010101010101010101010101010101010101010e0000006361737065722d6578616d706c65")
        // Test 2: ExecutableDeployItem serialization test as ModuleBytes
        // module_bytes blank
        let oneNamedArg = NamedArg()
        oneNamedArg.name = "amount"
        oneNamedArg.argsItem.clType = CLType.u512
        let u512 = U512Class.fromStringToU512(from: "100000000")
        oneNamedArg.argsItem.parsed = CLValueWrapper.u512(u512)
        oneNamedArg.argsItem.bytes = "0400e1f505"
        let runtimeArgs = RuntimeArgs()
        runtimeArgs.listNamedArg = [oneNamedArg]
        let emptyByte = Bytes()
        let edi: ExecutableDeployItem = .moduleBytes(module_bytes: emptyByte, args: runtimeArgs)
        let ediSerialization = ExecutableDeployItemSerializaton.serialize(from: edi)
        XCTAssert(ediSerialization == "00000000000100000006000000616d6f756e74050000000400e1f50508")
        // Test 3: ExecutableDeployItem serialization test as ModuleBytes
        // module_bytes not blank
        let oneNamedArg0 = NamedArg()
        oneNamedArg0.name = "amount"
        oneNamedArg0.argsItem.clType = CLType.u512
        let u5120 = U512Class.fromStringToU512(from: "999888666555444999887988887777666655556666777888999666999")
        oneNamedArg0.argsItem.parsed = CLValueWrapper.u512(u5120)
        oneNamedArg0.argsItem.bytes = "1837f578fca55492f299ea354eaca52b6e9de47d592453c728"
        let runtimeArgs0 = RuntimeArgs()
        runtimeArgs0.listNamedArg = [oneNamedArg0]
        let moduleBytes = Bytes.fromStrToBytes(from: "123456789123456789123456789123456789123456789123456789")
        let edi0: ExecutableDeployItem = .moduleBytes(module_bytes: moduleBytes, args: runtimeArgs0)
        let edi0Serialization = ExecutableDeployItemSerializaton.serialize(from: edi0)
        XCTAssert(edi0Serialization == "00360000003132333435363738393132333435363738393132333435363738393132333435363738393132333435363738393132333435363738390100000006000000616d6f756e74190000001837f578fca55492f299ea354eaca52b6e9de47d592453c72808")
        // Test 4: ExecutableDeployItem serialization test - as StoredContractByHash
        let edi2: ExecutableDeployItem = .storedContractByHash(hash: "c4c411864f7b717c27839e56f6f1ebe5da3f35ec0043f437324325d65a22afa4", entryPoint: "pclphXwfYmCmdITj8hnh", args: runtimeArgs0)
        let edi2Serialization = ExecutableDeployItemSerializaton.serialize(from: edi2)
        XCTAssert(edi2Serialization == "01c4c411864f7b717c27839e56f6f1ebe5da3f35ec0043f437324325d65a22afa41400000070636c7068587766596d436d6449546a38686e680100000006000000616d6f756e74190000001837f578fca55492f299ea354eaca52b6e9de47d592453c72808")
        // Test 5: ExecutableDeployItem serialization test - as StoredContractByName
        let oneNamedArg1 = NamedArg()
        oneNamedArg1.name = "quantity"
        oneNamedArg1.argsItem.clType = CLType.i32ClType
        oneNamedArg1.argsItem.parsed = CLValueWrapper.i32(1000)
        oneNamedArg1.argsItem.bytes = "e8030000"
        let runtimeArgs1 = RuntimeArgs()
        runtimeArgs1.listNamedArg = [oneNamedArg1]
        let payment: ExecutableDeployItem = .storedContractByName(name: "casper-example", entryPoint: "example-entry-point", args: runtimeArgs1)
        let edi1Serialization = ExecutableDeployItemSerializaton.serialize(from: payment)
        XCTAssert(edi1Serialization == "020e0000006361737065722d6578616d706c65130000006578616d706c652d656e7472792d706f696e7401000000080000007175616e7469747904000000e803000001")
        // Test 6: ExecutableDeployItem serialization test - as StoredVersionedContractByHash
        let edi3: ExecutableDeployItem = .storedVersionedContractByHash(hash: "b348fdd0d0b3f66468687df93141b5924f6bb957d5893c08b60d5a78d0b9a423", version: nil, entryPoint: "PsLz5c7JsqT8BK8ll0kF", args: runtimeArgs0)
        let edi3Serialization = ExecutableDeployItemSerializaton.serialize(from: edi3)
        XCTAssert(edi3Serialization == "03b348fdd0d0b3f66468687df93141b5924f6bb957d5893c08b60d5a78d0b9a423001400000050734c7a3563374a73715438424b386c6c306b460100000006000000616d6f756e74190000001837f578fca55492f299ea354eaca52b6e9de47d592453c72808")
        // Test 7: ExecutableDeployItem serialization test as  StoredVersionedContractByName
        let edi4: ExecutableDeployItem = .storedVersionedContractByName(name: "lWJWKdZUEudSakJzw1tn", version: 1632552656, entryPoint: "S1cXRT3E1jyFlWBAIVQ8", args: runtimeArgs0)
        let edi4Serialization = ExecutableDeployItemSerializaton.serialize(from: edi4)
        XCTAssert(edi4Serialization == "04140000006c574a574b645a5545756453616b4a7a7731746e01d0c64e61140000005331635852543345316a79466c574241495651380100000006000000616d6f756e74190000001837f578fca55492f299ea354eaca52b6e9de47d592453c72808")
        // Test 8: ExecutableDeployItem serialization test as Transfer
        let oneNamedArg2 = NamedArg()
        oneNamedArg2.name = "amount"
        oneNamedArg2.argsItem.clType = CLType.i32ClType
        oneNamedArg2.argsItem.parsed = CLValueWrapper.i32(1000)
        oneNamedArg2.argsItem.bytes = "e8030000"
        let runtimeArgs2 = RuntimeArgs()
        runtimeArgs2.listNamedArg = [oneNamedArg2]
        let session: ExecutableDeployItem = .transfer(args: runtimeArgs2)
        let sessionSerialization = ExecutableDeployItemSerializaton.serialize(from: session)
        XCTAssert(sessionSerialization == "050100000006000000616d6f756e7404000000e803000001")
        // Test 9. approval serialization test
        let da = DeployApprovalItem()
        da.signature = "012dbf03817a51794a8e19e0724884075e6d1fbec326b766ecfa6658b41f81290da85e23b24e88b1c8d9761185c961daee1adab0649912a6477bcd2e69bd91bd08"
        da.signer = "01d9bf2148748a85c89da5aad8ee0b0fc2d105fd39d41a4c796536354f0ae2900c"
        let deployApprovals: [DeployApprovalItem] = [da]
        let approvalSerialization = DeployApprovalSerialization.serialize(from: deployApprovals)
        XCTAssert(approvalSerialization == "0100000001d9bf2148748a85c89da5aad8ee0b0fc2d105fd39d41a4c796536354f0ae2900c012dbf03817a51794a8e19e0724884075e6d1fbec326b766ecfa6658b41f81290da85e23b24e88b1c8d9761185c961daee1adab0649912a6477bcd2e69bd91bd08")
        // Test 10. Test for the whole deploy
        // This is the deploy used as an example at this address
        // https: // caspernetwork.readthedocs.io/en/latest/implementation/serialization-standard.html?highlight=serialization#serialization-standard
        let deploy = Deploy()
        deploy.header = deployHeader
        deploy.payment = payment
        deploy.session = session
        deploy.approvals = deployApprovals
        deploy.hash = "01da3c604f71e0e7df83ff1ab4ef15bb04de64ca02e3d2b78de6950e8b5ee187"
        let deploySerialization = DeploySerialization.serialize(fromDeploy: deploy)
        XCTAssert(deploySerialization == "01d9bf2148748a85c89da5aad8ee0b0fc2d105fd39d41a4c796536354f0ae2900ca856a4d37501000080ee36000000000001000000000000004811966d37fe5674a8af4001884ea0d9042d1c06668da0c963769c3a01ebd08f0100000001010101010101010101010101010101010101010101010101010101010101010e0000006361737065722d6578616d706c6501da3c604f71e0e7df83ff1ab4ef15bb04de64ca02e3d2b78de6950e8b5ee187020e0000006361737065722d6578616d706c65130000006578616d706c652d656e7472792d706f696e7401000000080000007175616e7469747904000000e803000001050100000006000000616d6f756e7404000000e8030000010100000001d9bf2148748a85c89da5aad8ee0b0fc2d105fd39d41a4c796536354f0ae2900c012dbf03817a51794a8e19e0724884075e6d1fbec326b766ecfa6658b41f81290da85e23b24e88b1c8d9761185c961daee1adab0649912a6477bcd2e69bd91bd08")
    }
}
