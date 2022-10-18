// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract NewDID {
    string[] context = [
        "https://www.w3.org/ns/did/v1",
        "https://w3id.org/security/suites/jws-2020/v1"
    ];
    string[] accept = ["didcomm/v2", "didcomm/aip2;env=rfc587"];
    string[] routingKeys = ["did:example:somemediator#somekey"];

    struct DIDDocument {
        string[] context;
        string NFid;
        string class;
        AuthDetail[] authentication;
        CapInvo[] capabilityInvocation;
        CapDeleg[] capabilityDelegation;
        AssertMethod[] assertionMethod;
        KeyAgree[] keyAgreement;
        ServiceEndpoint[] serviceEndpoint;
    }

    struct AuthDetail {
        string id;
        string _type;
        string controller;
        string kty;
        string crv;
        string x;
        string y;
    }

    mapping(address => DIDDocument) did_document;

   
    struct CapInvo {
        string id;
        string _type;
        string controller;
        string kty;
        string crv;
        string x;
        string y;
    }

    struct CapDeleg {
        string id;
        string _type;
        string controller;
        string kty;
        string crv;
        string x;
        string y;
    }

    struct AssertMethod {
        string id;
        string _type;
        string controller;
        string kty;
        string crv;
        string x;
        string y;
    }

    struct KeyAgree {
        string id;
        string _type;
        string controller;
        string kty;
        string crv;
        string x;
        string y;
    }

    struct ServiceEndpoint {
        string id;
        string _type;
        string uri;
        string[] accept;
        string[] routingKeys;
    }

     function setDoc(
        address key,
        string memory id,
        string memory class,
        string memory _type,
        string memory controller,
        string memory kty,
        string memory crv,
        string memory x,
        string memory y
    ) public {
        did_document[key].context = context;
        //did_document[key].id = id;
        did_document[key].class = class;

        did_document[key].authentication.push(
            AuthDetail({
                id: id,
                _type: _type,
                controller: controller,
                kty: kty,
                crv: crv,
                x: x,
                y: y
            })
        );

        did_document[key].capabilityInvocation.push(
            CapInvo({
                id: id,
                _type: _type,
                controller: controller,
                kty: kty,
                crv: crv,
                x: x,
                y: y
            })
        );

        did_document[key].capabilityDelegation.push(
            CapDeleg({
                id: id,
                _type: _type,
                controller: controller,
                kty: kty,
                crv: crv,
                x: x,
                y: y
            })
        );

        did_document[key].assertionMethod.push(
            AssertMethod({
                id: id,
                _type: _type,
                controller: controller,
                kty: kty,
                crv: crv,
                x: x,
                y: y
            })
        );
        

        did_document[key].keyAgreement.push(
            KeyAgree({
                id: id,
                _type: _type,
                controller: controller,
                kty: kty,
                crv: crv,
                x: x,
                y: y
            })
        );

        did_document[key].serviceEndpoint.push(
            ServiceEndpoint({
                id: id,
                _type: _type,
                uri: "controller",
                accept: accept,
                routingKeys: routingKeys
            })
        );
    }


    function getDoc(address key) public view  returns(string memory class, AuthDetail[] memory, CapInvo[] memory, CapDeleg[] memory, AssertMethod[] memory, KeyAgree[] memory, ServiceEndpoint[] memory){
        return(did_document[key].class, did_document[key].authentication, did_document[key].capabilityInvocation, did_document[key].capabilityDelegation,  did_document[key].assertionMethod, did_document[key].keyAgreement, did_document[key].serviceEndpoint);
    }

}