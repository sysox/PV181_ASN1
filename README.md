# PV181 – ASN.1 and public-key formats

Keys and signatures are stored as ASN.1 structures in DER (binary) or PEM (Base64 text).
The seminar goes from **bytes → key files → DER structure → named values → the mathematics behind them**.

| Notebook | Role | Content |
|---|---|---|
| `01_encodings` | warm-up, go through briefly | integers, bytes, hex, Base64, byte order |
| `02_openssl_keys` | **core** | RSA/EC key files, PEM vs DER, `openssl asn1parse` – creates the keys for the other notebooks |
| `03_der_parsing` | **core** | tag, length, value – a small DER parser |
| `04_asn1tools_rsa_math` | **core** | ASN.1 grammar names the RSA values; RSA relations |
| `05_rsa_from_scratch` | bonus | RSA computation and CRT, checked with OpenSSL |
| `06_ec_from_scratch` | bonus | EC arithmetic, ECDH, ECDSA, checked with OpenSSL |

Work in order. Solutions are in `solutions/`, slides in `slides/`.

## Start

Run the launcher for your system: `start_jupyter.cmd` (Windows), `start_jupyter.command` (macOS) or `./start_jupyter.sh` (Linux).
The first start installs the packages from `requirements.txt`. Add `lab` for JupyterLab, e.g. `./start_jupyter.sh lab`.

The notebooks run `openssl`; on Windows the launcher uses the one from [Git for Windows](https://git-scm.com/download/win).

On aisa: run the OpenSSL commands from notebook 02 there (without `!`) and copy the keys into `notebooks/`:

```
scp "xlogin@aisa.fi.muni.cz:pv181/*.pem" "xlogin@aisa.fi.muni.cz:pv181/*.der" .
```
