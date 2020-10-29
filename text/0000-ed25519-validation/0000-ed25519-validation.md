# ED25519 Validation

## Summary

The implementation of ED25519, our choice signature scheme for signing transactions in IOTA, is formally defined in [RFC 8032](https://tools.ietf.org/html/rfc8032). However, flaws in the RFC and its various implementations lead to the specification of [ZIP-215](https://zips.z.cash/zip-0215), that amends the original RFC.

Iota will adopt the ZIP-215 specification. This in practice means change in the following sections:
1. Decoding of elliptic curve point described in [section 5.1.3](https://tools.ietf.org/html/rfc8032#section-5.1.3)
2. The validation itself as described in [section 5.1.7](https://tools.ietf.org/html/rfc8032#section-5.1.7).
3. A correction to the non-malleability claim  in [section 8.4](https://tools.ietf.org/html/rfc8032#section-8.4). The holder of the secret key can always amend the signature and keep it valid.

Compatible implementations for [rust](https://github.com/ZcashFoundation/ed25519-zebra) and [go](https://github.com/hdevalence/ed25519consensus) are available.


## Motivation

Based on [research done by Henry de Valence](https://hdevalence.ca/blog/2020-10-04-its-25519am) we know that: 
1. Not all known implementations follow the decoding rules defined in RFC 8032. This causes validation results to vary across implementations.
2. Even if the above point is fixed, the validation rules described in the RFC are not strict. So validation results vary even across implementations that adhere to RFC 8032.
3. Even if the above points are fixed, we should note that a user holding the secret key to a signed message, can amend the signature so it remains valid.

Points 1 and 2 are very concerning since they can cause a breach of consensus across node implementations! For example, Hornet may validate a transaction and mutate the ledger state, while Bee may invalidate and discard the same transaction. A fork in the ledger could only be resolved outside of the protocol, and will probably lead to contention in the community.

The 3rd point is more subtle and shouldn't be a problem in the core protocol but there should be awareness of it. It may be a future problem for 2nd layer protocols in the future, similarly to how [tranaction malleability in bitcoin presented an issue for the lightning network](https://en.bitcoinwiki.org/wiki/Transaction_Malleability#How_Does_Transaction_Malleability_Affect_The_Lightning_Network.3F). Any issue that may rise can probably be circumvented by using the [transaction essence hash](https://github.com/luca-moser/protocol-rfcs/blob/signed-tx-payload/text/0000-transaction-payload/0000-transaction-payload.md#transaction-essence-data).

The above problems force us to use a better definition, such as ZIP-215, for ed25519 validation.


## Specification Details


To be [ZIP-215](https://zips.z.cash/zip-0215) compatible we should follow the specifications of [RFC 8032](https://tools.ietf.org/html/rfc8032) with the changes specified below.
We will mark additions to the RFC in **bold**, and deletions with ~~strike through~~.



[section 5.1.3](https://tools.ietf.org/html/rfc8032#section-5.1.3) (decoding):

*Here we allow less strict rules*

>  1.  First, interpret the string as an integer in little-endian
       representation.  Bit 255 of this number is the least significant
       bit of the x-coordinate and denote this value x_0.  The
       y-coordinate is recovered simply by clearing this bit.  If the
       resulting value is >= p, ~~decoding fails~~ **evaluate it as the modulus of p**.
>     ...

>  4. Finally, use the x_0 bit to select the right square root.  ~~If
       x = 0, and x_0 = 1, decoding fails.  Otherwise,~~ If x_0 != x mod
       2, set x <-- p - x.  Return the decoded point (x,y)


[section 5.1.7](https://tools.ietf.org/html/rfc8032#section-5.1.7) (validation):

*First point is actually unchanged, but due to some implementations failing to comply with validating constraints, it is mentioned*

>   1.  To verify a signature on a message M using public key A, with F
       being 0 for Ed25519ctx, 1 for Ed25519ph, and if Ed25519ctx or
       Ed25519ph is being used, C being the context, first split the
       signature into two 32-octet halves.  Decode the first half as a
       point R, and the second half as an integer S, in the range
       0 <= s < L.  Decode the public key A as point A'.  If any of the
       decodings fail (including S being out of range), the signature is
       invalid.
       

*Here we specify a single equation*
>3.  **Must** check the group equation [8][S]B = [8]R + [8][k]A'.  ~~It's
       sufficient, but not required, to instead check [S]B = R + [k]A'.~~

A note is added to [section 8.4](https://tools.ietf.org/html/rfc8032#section-8.4) (malleability).

>  Some systems assume signatures are not malleable: that is, given a
   valid signature for some message under some key, the attacker can't
   produce another valid signature for the same message and key.
>   
>  Ed25519 and Ed448 signatures are not malleable due to the
   verification check that decoded S is smaller than l.  Without this
   check, one can add a multiple of l into a scalar part and still pass
   signature verification, resulting in malleable signatures.
>
> **Yet, the holder of the secret key can always produce another signature for
> the same message. In a cryptocurrency system, individual users may be mallicious,
> so signatures should be considered malleable.**

### Explanations:

#### Quick Background on Ed25519

The signature scheme relies on point additions operations that are done over a discrete [Twisted Edward's curve](https://en.wikipedia.org/wiki/Twisted_Edwards_curve). The particular chosen curve has `8l` points where `l` is a large prime, `2^252 + 27742317777372353535851937790883648493`. Those points turn out to form an [abelian group](https://en.wikipedia.org/wiki/Abelian_group), so points addition can be defined. Multiplication of a point by an integer scalar, `n` is defined as adding the point `n` times to itself. The identity point, 0, is the [point at infinity](https://en.wikipedia.org/wiki/Point_at_infinity).

Ed25519 also specifies a base point, `B`, on the curve that we will use for signing and verification. It also holds that `lB = 0`.

In order to sign a message the rough process is:
1. The signer uses the secret key to generate an integer `a`. Then he calculates `A = aB`. The resulting point `A` is the public key.
2. The signer creates a nonce `r` and a commitment point `R = rB`
3. The signer will calculate `k` as the hash of`R`,`A`, and the message.
4. Calculate integer `s = (r + ka) mod l`.
5. Publish the signature pair `(s, R)`

#### Decoding:

The ed25519 signature is encoded as the concatenation`R||s` where `s` is 32 byte unsigned little endian integer.

`R` is encoded in 32 bytes or 256 bits. The first 255 bits encode the `y` coordinate as a little endian integer, and the last bit (LSB) encodes the sign of the `x` coordinate. The `x` coordinate can be calculated from the curve equation as described in [section 5.1.3](https://tools.ietf.org/html/rfc8032#section-5.1.3). There are 2 possible solutions (or no solutions), hence is the reason for encoding the sign. Note that the coordinates of the points on the curve are defined over a prime field `Z_p` using the prime `p = 2^255 - 19`.

When we decode the `R` point in the signature there are 2 edge conditions:
1. What happens if `y >= p`? Note that there are only 19 possible values, and not all map to possible points on the curve.
2. What happens if`x = -0` due to the sign bit?

RFC 8032 invalidates the signature in those cases.
ZIP-215 accepts both cases. `y` is always calculated as the modulus of `p`. A negative 0 is simply 0.

It is worth to note that due to allowing different encodings to the same point, one cannot check point equality by doing byte per byte comparisons.

### Validation 

The original RFC 8032 allows for 2 possible equation involving point operations to validate the signature. One with a cofactor of 8, and another one cofactorless:
`8sB = 8R + 8kA'`
`sB = R + kA'`

`s,R` is the signature scalar and point as defined before.
`B` is a pre-chosen base point on the curve. Its value is defined in [RFC 7748](https://tools.ietf.org/html/rfc7748#section-4.1).
`A'` - Is the decoded public key curve point.
`k` - The 64 byte hash of the concatenation of the bytes of `R`, the public key, and the signed message bytes.

The equations have been derived by multiplying the definition of `s`, `s = (r + ka) mod l`, by `B`. We are using the fact that `lB = 0`.
The first equation is the multiplication of the second one by 8. So every solution that satisfies the latter equation satisfies the first. Surprisingly, not every solution that satisfies the first will satisfy the latter. The freedom of choice allowed by RFC 8032 lead to different implementations yielding different validation results.
ZIP-215 chooses to enforce the first equation: `8SB = 8R + 8kA'`. This is because it allows for batch verification of signatures.

##### A mathematical explanation of the above

As mentioned, the abelian group that the curve points is of order `8l`. Let denote the group as `G`. From `G` we can extract two different subgroups, `Q` and `T`, so that `Q` has an order of `l` and `T` an order of 8. Each point `g` in `G` can be written as the sum of points `q` and `t` from `Q` and `T` respectively. Now if we multiply the equation `g = q + t` by 8 we get `8g = 8q + 8t = 8q`. The `t` torsion element gets canceled out by the multiplication, but `q` does not. This is because `l` is coprime with 8, and every point `t` is of order divisible by 8. So in essence we are mapping the points from `G` to `Q`.
So the first equation projects from `G` to `Q`, thus it has more solutions because different points in `G` map to the same points in `Q` by the pigeon hole principle. However, now that we are effectively operating over a prime order group we are getting useful properties that allow us to do batch verification.


### Malleability

Third party malleability is prevented by the RFC 8032, by constraining `0<=s<l`. This is to prevent generating `s'` that will be congruent to the original `s` mod `l`. However, some implementations didn't code this constraint correctly so ZIP-215 explicitly specifies it.

Given ZIP-215 decoding and validation, it is clear that we have some malleability vectors. 

However, even a choice of stricter constraints, namely the canonical RFC 8032 decoding and the cofactorless validation, can not prevent the holder of the secret key to create different signatures to the same message.

This is because ed25519, similar to precursory [ECDSA](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm), has a component that may be random. This is because the signature algorithm is based on a linear combination of a known base point and the public key point that add up to an arbitrary target point, `R`, committed by the signer. A signer may choose this target randomly but this may lead to weak signatures if not done properly. 

In the second point of [section 5.1.6](https://tools.ietf.org/html/rfc8032#section-5.1.6) of RFC 8032, a deterministic method of calculating an integer `r` is specified by hashing some of the private key bits with the message. However, if the signer will use any other method to generate this value it will be unnoticed by the validator. The result is that there are practically countless amount of different valid signatures that may be associated to a certain message and public key.

## Drawbacks

1. The non-canonical encoding ensues an arguably needless deviation from the original RFC 8032. It affects both the public key `A` and the commitment point `R.` It also adds more possible encoding to 6 points on the curve that constitute a 3rd party malleability exploit.
2. Our choice of cofactor validation equation is a bit harder to compute than the cofactorless. It is also less strict, allowing for more solutions and thus opens more malleability vectors.


## Rationale and alternatives

Given the drawbacks, one can argue that deviation from ZIP-215 with two plausible changes could be:
1. Use RFC-4038 canonical encoding
2. Only use the cofactorless validation equation, which is a bit faster and more strict.

The [XEdDSA](https://signal.org/docs/specifications/xeddsa/#xeddsa) specification by Signal does exactly that.
However, the cofactor validation, even though marginally slower than cofactorless by 1-2%, enables batch signature verification. Batched verification may allow up to to 2x better performance, making cofactor validation a win.

Using non-canonical encoding doesn't seem to have much rationale. It leads to a 3rd party signature malleability for 6 possible points. ZIP-215 specified this new encoding so that the ZCash protocol would remain backwards compatible with the libsodium library. For IOTA this is not a concern, so one can argue that allowing non-canonical encoding will add a quirky behavior and has only disadvantages.

On the other hand it is hard to point out to any security risks.
The malleability drawback can't be fully mitigated as explained in [Malleability](#Malleability). Arguably, adding more vectors doesn't change much. Malleability is also not a known security concern for the core protocol. It may potentially affect second layer services, but a correct design can circumvent the issues.

Given the considerations at hand, it was decided to use an existing specification rather than create a new one.

## Unresolved questions
1. Allowing non-canonical encoding for public keys can be harmful?
2. Should we do any farther audit/tests to the existing zip-215 implementations? 

