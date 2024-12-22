# Vaccine Tracking Smart Contract

## About
A blockchain-based smart contract system designed for tracking vaccine distribution, administration, and cold chain management. This contract ensures secure, transparent, and efficient management of vaccine inventories while maintaining compliance with healthcare standards.

## Features
- **Contract Administration**
  - Secure ownership management
  - Healthcare provider authorization
  - Storage facility registration

- **Vaccine Batch Management**
  - Batch registration and tracking
  - Expiration date monitoring
  - Temperature breach tracking
  - Real-time inventory management

- **Patient Vaccination Records**
  - Secure patient vaccination history
  - Multiple dose tracking
  - Adverse reaction reporting
  - Medical exemption documentation

- **Storage Facility Management**
  - Temperature monitoring
  - Capacity tracking
  - Location management

## Technical Specifications

### Data Structures

#### Vaccine Inventory
```clarity
{
    batch-identifier: string-ascii 32,
    manufacturer-name: string-ascii 50,
    vaccine-product-name: string-ascii 50,
    production-date: uint,
    expiration-date: uint,
    remaining-doses: uint,
    required-storage-temperature: int,
    current-batch-status: string-ascii 20,
    temperature-violation-count: uint,
    storage-location: string-ascii 100,
    batch-specific-notes: string-ascii 500
}
```

#### Vaccination Records
```clarity
{
    patient-id: string-ascii 32,
    immunization-history: list[10],
    total-doses-received: uint,
    adverse-reactions: list[5],
    medical-exemption: optional string-ascii 200
}
```

### Constants
- Minimum Storage Temperature: -70°C
- Maximum Storage Temperature: 8°C
- Minimum Days Between Doses: 21 days
- Maximum Doses Per Patient: 4

## Error Codes
- `ERROR-UNAUTHORIZED-ACCESS (u100)`: Unauthorized access attempt
- `ERROR-INVALID-VACCINE-BATCH (u101)`: Invalid batch data
- `ERROR-DUPLICATE-BATCH (u102)`: Batch already exists
- `ERROR-BATCH-UNAVAILABLE (u103)`: Batch not found
- `ERROR-DEPLETED-VACCINE-STOCK (u104)`: Insufficient vaccine quantity
- `ERROR-INVALID-PATIENT-IDENTIFIER (u105)`: Invalid patient ID
- `ERROR-DUPLICATE-PATIENT-VACCINATION (u106)`: Patient already vaccinated
- `ERROR-STORAGE-TEMPERATURE-VIOLATION (u107)`: Temperature out of range
- `ERROR-BATCH-PAST-EXPIRATION (u108)`: Expired vaccine batch
- `ERROR-INVALID-VACCINATION-SITE (u109)`: Invalid vaccination location
- `ERROR-MAXIMUM-VACCINATION-LIMIT (u110)`: Maximum doses reached
- `ERROR-INSUFFICIENT-DOSE-INTERVAL (u111)`: Minimum interval not met
- `ERROR-ADMIN-ONLY-OPERATION (u112)`: Contract owner only operation
- `ERROR-INVALID-DATA-FORMAT (u113)`: Invalid input format
- `ERROR-INVALID-EXPIRATION-DATE (u114)`: Invalid expiry date
- `ERROR-INVALID-FACILITY-CAPACITY (u115)`: Invalid storage capacity

## Usage Guide

### Administrator Functions

1. **Transfer Administrator Rights**
```clarity
(transfer-administrator-rights new-administrator)
```

2. **Register Medical Provider**
```clarity
(register-medical-provider 
    provider-address
    medical-role
    facility-name
    license-expiry)
```

3. **Register Storage Facility**
```clarity
(register-facility
    facility-identifier
    physical-address
    storage-capacity-limit)
```

### Provider Functions

1. **Register Vaccine Batch**
```clarity
(register-vaccine-batch 
    batch-identifier
    manufacturer-name
    vaccine-product-name
    production-date
    expiration-date
    initial-stock
    required-storage-temperature
    storage-location)
```

2. **Record Vaccination**
```clarity
(record-vaccination
    patient-id
    batch-identifier
    vaccination-site)
```

3. **Update Batch Status**
```clarity
(update-batch-status
    batch-identifier
    updated-status)
```

### Query Functions

1. **Get Batch Details**
```clarity
(get-batch-details batch-identifier)
```

2. **Get Patient Record**
```clarity
(get-patient-record patient-id)
```

3. **Verify Batch Validity**
```clarity
(verify-batch-validity batch-identifier)
```

## Security Considerations

1. **Access Control**
   - Only authorized administrators can register providers
   - Only authorized providers can record vaccinations
   - Strict validation of all input parameters

2. **Data Integrity**
   - Temperature breach tracking
   - Batch status monitoring
   - Expiration date validation

3. **Patient Safety**
   - Dose interval enforcement
   - Maximum dose limit
   - Adverse reaction tracking

## Best Practices

1. **Batch Registration**
   - Always verify manufacturer details
   - Ensure accurate temperature requirements
   - Set appropriate expiration dates

2. **Vaccination Recording**
   - Verify patient identification
   - Check batch validity before administration
   - Record accurate vaccination site information

3. **Temperature Monitoring**
   - Regular temperature checks
   - Immediate reporting of breaches
   - Proper documentation of violations

## Limitations
1. Maximum 10 vaccination records per patient
2. Maximum 4 doses per patient
3. Temperature breach count limit of 2 before batch compromise
4. Fixed minimum interval between doses (21 days)