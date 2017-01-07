/*
 * DO NOT EDIT.
 *
 * Generated by the protocol buffer compiler.
 * Source: echo.proto
 *
 */

/*
 *
 * Copyright 2016, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

import Foundation
import gRPC

public enum Echo_EchoServerError : Error {
  case endOfStream
}

/// To build a server, implement a class that conforms to this protocol.
public protocol Echo_EchoProvider {
  func get(request : Echo_EchoRequest) throws -> Echo_EchoResponse
  func expand(request : Echo_EchoRequest, session : Echo_EchoExpandSession) throws
  func collect(session : Echo_EchoCollectSession) throws
  func update(session : Echo_EchoUpdateSession) throws
}
// Get (Unary)
public class Echo_EchoGetSession {
  private var handler : gRPC.Handler
  private var provider : Echo_EchoProvider

  /// Create a session.
  fileprivate init(handler:gRPC.Handler, provider: Echo_EchoProvider) {
    self.handler = handler
    self.provider = provider
  }

  /// Run the session. Internal.
  fileprivate func run(queue:DispatchQueue) {
    do {
      try handler.receiveMessage(initialMetadata:Metadata()) {(requestData) in
        if let requestData = requestData {
          let requestMessage = try! Echo_EchoRequest(protobuf:requestData)
          let replyMessage = try! self.provider.get(request:requestMessage)
          try self.handler.sendResponse(message:replyMessage.serializeProtobuf(),
                                        statusCode: 0,
                                        statusMessage: "OK",
                                        trailingMetadata:Metadata())

        }
      }
    } catch (let callError) {
      print("grpc error: \(callError)")
    }
  }
}

// Expand (Server Streaming)
public class Echo_EchoExpandSession {
  private var handler : gRPC.Handler
  private var provider : Echo_EchoProvider

  /// Create a session.
  fileprivate init(handler:gRPC.Handler, provider: Echo_EchoProvider) {
    self.handler = handler
    self.provider = provider
  }

  /// Send a message. Nonblocking.
  public func Send(_ response: Echo_EchoResponse) throws {
    try! handler.sendResponse(message:response.serializeProtobuf()) {}
  }

  /// Run the session. Internal.
  fileprivate func run(queue:DispatchQueue) {
    do {
      try self.handler.receiveMessage(initialMetadata:Metadata()) {(requestData) in
        if let requestData = requestData {
          let requestMessage = try! Echo_EchoRequest(protobuf:requestData)
          // to keep providers from blocking the server thread,
          // we dispatch them to another queue.
          queue.async {
            try! self.provider.expand(request:requestMessage, session: self)
            try! self.handler.sendStatus(statusCode:0,
                                         statusMessage:"OK",
                                         trailingMetadata:Metadata(),
                                         completion:{})
          }
        }
      }
    } catch (let callError) {
      print("grpc error: \(callError)")
    }
  }
}

// Collect (Client Streaming)
public class Echo_EchoCollectSession {
  private var handler : gRPC.Handler
  private var provider : Echo_EchoProvider

  /// Create a session.
  fileprivate init(handler:gRPC.Handler, provider: Echo_EchoProvider) {
    self.handler = handler
    self.provider = provider
  }

  /// Receive a message. Blocks until a message is received or the client closes the connection.
  public func Receive() throws -> Echo_EchoRequest {
    let done = NSCondition()
    var requestMessage : Echo_EchoRequest?
    try self.handler.receiveMessage() {(requestData) in
      if let requestData = requestData {
        requestMessage = try! Echo_EchoRequest(protobuf:requestData)
      }
      done.lock()
      done.signal()
      done.unlock()
    }
    done.lock()
    done.wait()
    done.unlock()
    if requestMessage == nil {
      throw Echo_EchoServerError.endOfStream
    }
    return requestMessage!
  }

  /// Send a response and close the connection.
  public func SendAndClose(_ response: Echo_EchoResponse) throws {
    try self.handler.sendResponse(message:response.serializeProtobuf(),
                                  statusCode: 0,
                                  statusMessage: "OK",
                                  trailingMetadata: Metadata())
  }

  /// Run the session. Internal.
  fileprivate func run(queue:DispatchQueue) {
    do {
      try self.handler.sendMetadata(initialMetadata:Metadata()) {
        queue.async {
          try! self.provider.collect(session:self)
        }
      }
    } catch (let callError) {
      print("grpc error: \(callError)")
    }
  }
}

// Update (Bidirectional Streaming)
public class Echo_EchoUpdateSession {
  private var handler : gRPC.Handler
  private var provider : Echo_EchoProvider

  /// Create a session.
  fileprivate init(handler:gRPC.Handler, provider: Echo_EchoProvider) {
    self.handler = handler
    self.provider = provider
  }

  /// Receive a message. Blocks until a message is received or the client closes the connection.
  public func Receive() throws -> Echo_EchoRequest {
    let done = NSCondition()
    var requestMessage : Echo_EchoRequest?
    try self.handler.receiveMessage() {(requestData) in
      if let requestData = requestData {
        requestMessage = try! Echo_EchoRequest(protobuf:requestData)
      }
      done.lock()
      done.signal()
      done.unlock()
    }
    done.lock()
    done.wait()
    done.unlock()
    if requestMessage == nil {
      throw Echo_EchoServerError.endOfStream
    }
    return requestMessage!
  }

  /// Send a message. Nonblocking.
  public func Send(_ response: Echo_EchoResponse) throws {
    try handler.sendResponse(message:response.serializeProtobuf()) {}
  }

  /// Close a connection. Blocks until the connection is closed.
  public func Close() {
    let done = NSCondition()
    try! self.handler.sendStatus(statusCode: 0,
                                 statusMessage: "OK",
                                 trailingMetadata: Metadata()) {
                                  done.lock()
                                  done.signal()
                                  done.unlock()
    }
    done.lock()
    done.wait()
    done.unlock()
  }

  /// Run the session. Internal.
  fileprivate func run(queue:DispatchQueue) {
    do {
      try self.handler.sendMetadata(initialMetadata:Metadata()) {
        queue.async {
          try! self.provider.update(session:self)
        }
      }
    } catch (let callError) {
      print("grpc error: \(callError)")
    }
  }
}


/// Main server for generated service
public class Echo_EchoServer {
  private var address: String
  private var server: gRPC.Server
  private var provider: Echo_EchoProvider?

  /// Create a server that accepts insecure connections.
  public init(address:String,
              provider:Echo_EchoProvider) {
    gRPC.initialize()
    self.address = address
    self.provider = provider
    self.server = gRPC.Server(address:address)
  }

  /// Create a server that accepts secure connections.
  public init?(address:String,
               certificateURL:URL,
               keyURL:URL,
               provider:Echo_EchoProvider) {
    gRPC.initialize()
    self.address = address
    self.provider = provider
    guard
      let certificate = try? String(contentsOf: certificateURL),
      let key = try? String(contentsOf: keyURL)
      else {
        return nil
    }
    self.server = gRPC.Server(address:address, key:key, certs:certificate)
  }

  /// Start the server.
  public func start(queue:DispatchQueue = DispatchQueue.global()) {
    guard let provider = self.provider else {
      assert(false) // the server requires a provider
    }
    server.run {(handler) in
      print("Server received request to " + handler.host
        + " calling " + handler.method
        + " from " + handler.caller)

      switch handler.method {
      case "/echo.Echo/Get":
        Echo_EchoGetSession(handler:handler, provider:provider).run(queue:queue)
      case "/echo.Echo/Expand":
        Echo_EchoExpandSession(handler:handler, provider:provider).run(queue:queue)
      case "/echo.Echo/Collect":
        Echo_EchoCollectSession(handler:handler, provider:provider).run(queue:queue)
      case "/echo.Echo/Update":
        Echo_EchoUpdateSession(handler:handler, provider:provider).run(queue:queue)
      default:
        break // handle unknown requests
      }
    }
  }
}