class VisaCustomerWalletApproveTask: CardSessionRunnable {
    typealias TaskResult = CompletionResult<SignHashResponse>
    private let targetAddress: String
    private let approveData: Data

    private let visaUtilities = VisaUtilities()
    private let pubKeySearchUtility = VisaWalletPublicKeySearchUtility(isTestnet: false)

    init(
        targetAddress: String,
        approveData: Data
    ) {
        self.targetAddress = targetAddress
        self.approveData = approveData
    }

    func run(in session: CardSession, completion: @escaping TaskResult) {
        let scanCard = AppScanTask()
        scanCard.run(in: session) { result in
            switch result {
            case .success(let response):
                self.proceedApprove(scanResponse: response, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private extension VisaCustomerWalletApproveTask {
    func proceedApprove(scanResponse: AppScanTaskResponse, in session: CardSession, completion: @escaping TaskResult) {
        let config = UserWalletConfigFactory(scanResponse.getCardInfo()).makeConfig()

        guard let derivationStyle = config.derivationStyle else {
            proceedApproveWithLegacyCard(card: scanResponse.card, in: session, completion: completion)
            return
        }

        guard let derivationPath = visaUtilities.visaDefaultDerivationPath(style: derivationStyle) else {
            // Is this possible?..
            return
        }

        do {
            let searchUtility = VisaWalletPublicKeySearchUtility(isTestnet: false)
            let walletPublicKey = try searchUtility.findPublicKey(
                targetAddress: targetAddress,
                derivationPath: derivationPath,
                on: scanResponse.card
            )

            signApproveData(
                targetWalletPublicKey: walletPublicKey,
                derivationPath: derivationPath,
                in: session,
                completion: completion
            )
        } catch {
            switch error {
            case .missingDerivedKeys:
                deriveKeys(scanResponse: scanResponse, derivationPath: derivationPath, in: session, completion: completion)
            default:
                completion(.failure(.underlying(error: error)))
            }
        }
    }

    func proceedApproveWithLegacyCard(card: Card, in session: CardSession, completion: @escaping TaskResult) {
        do {
            let searchUtility = VisaWalletPublicKeySearchUtility(isTestnet: false)
            let publicKey = try searchUtility.findPublicKey(targetAddress: targetAddress, derivationPath: nil, on: card)
            signApproveData(targetWalletPublicKey: publicKey, derivationPath: nil, in: session, completion: completion)
        } catch {
            completion(.failure(.underlying(error: error)))
        }
    }

    func deriveKeys(
        scanResponse: AppScanTaskResponse,
        derivationPath: DerivationPath,
        in session: CardSession,
        completion: @escaping TaskResult
    ) {
        let targetCurve = visaUtilities.visaBlockchain.curve
        guard let wallet = scanResponse.card.wallets.first(where: { $0.curve == targetCurve }) else {
            completion(.failure(.walletNotFound))
            return
        }

        let derivationTask = DeriveWalletPublicKeyTask(walletPublicKey: wallet.publicKey, derivationPath: derivationPath)
        derivationTask.run(in: session) { result in
            switch result {
            case .success(let extendedPubKey):
                self.signApproveData(
                    targetWalletPublicKey: extendedPubKey.publicKey,
                    derivationPath: derivationPath,
                    in: session,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func signApproveData(
        targetWalletPublicKey: Data,
        derivationPath: DerivationPath?,
        in session: CardSession,
        completion: @escaping TaskResult
    ) {
        let signTask = SignHashCommand(
            hash: approveData,
            walletPublicKey: targetWalletPublicKey,
            derivationPath: derivationPath
        )

        signTask.run(in: session, completion: completion)
    }
}