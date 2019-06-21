/*
 * Copyright 2019, gRPC Authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Foundation
import GRPC
import NIO
import NIOSSL

/// Makes a client connections for gRPC interoperability testing.
///
/// - Parameters:
///   - host: The host to connect to.
///   - port: The port to connect to.
///   - eventLoopGroup: Event loop group to run client connection on.
///   - useTLS: Whether to use TLS or not.
/// - Returns: A future of a `ClientConnection`.
public func makeInteroperabilityTestClientConnection(
  host: String,
  port: Int,
  eventLoopGroup: EventLoopGroup,
  useTLS: Bool
) throws -> EventLoopFuture<ClientConnection> {
  var configuration = ClientConnection.Configuration(
    target: .hostAndPort(host, port),
    eventLoopGroup: eventLoopGroup)

  if useTLS {
    // The CA certificate has a common name of "*.test.google.fr", use the following host override
    // so we can do full certificate verification.
    let hostOverride = "foo.test.google.fr"
    let tlsConfiguration = TLSConfiguration.forClient(
      trustRoots: .certificates([InteroperabilityTestCredentials.caCertificate]),
      applicationProtocols: ["h2"])

    let context = try NIOSSLContext(configuration: tlsConfiguration)
    configuration.tlsConfiguration = .init(sslContext: context, hostnameOverride: hostOverride)
  }

  return ClientConnection.start(configuration)
}