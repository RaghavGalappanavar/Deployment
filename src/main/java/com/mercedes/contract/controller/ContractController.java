package com.mercedes.contract.controller;

import com.mercedes.contract.dto.ContractDetailsResponse;
import com.mercedes.contract.dto.ContractRequest;
import com.mercedes.contract.dto.ContractResponse;
import com.mercedes.contract.service.ContractService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.Map;
import com.fasterxml.jackson.databind.JsonNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.net.URI;

/**
 * Contract Controller handling HTTP requests
 * Follows Controller → Service → Repository pattern
 * Handles input validation, request parsing, and response construction
 */
@RestController
@RequestMapping("/v1/contracts")
@Tag(name = "Contract Management", description = "APIs for contract generation and retrieval")
public class ContractController {

    private static final Logger logger = LoggerFactory.getLogger(ContractController.class);

    private final ContractService contractService;

    @Autowired
    public ContractController(ContractService contractService) {
        this.contractService = contractService;
    }

    /**
     * DEBUG endpoint to analyze raw JSON structure
     */
    @PostMapping("/debug")
    public ResponseEntity<String> debugContractRequest(
            @RequestBody String rawRequestBody,
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            HttpServletRequest httpRequest) {

        logger.info("=== DEBUG ENDPOINT ===");
        logger.info("Raw request details - Content-Type: {}, Content-Length: {}",
                   httpRequest.getContentType(), httpRequest.getContentLength());

        logger.info("Raw JSON request body: {}", rawRequestBody);

        // Parse the JSON manually to understand the structure
        try {
            com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();
            com.fasterxml.jackson.databind.JsonNode jsonNode = objectMapper.readTree(rawRequestBody);

            logger.info("Parsed JSON structure:");
            logger.info("- purchaseRequestId: {}", jsonNode.has("purchaseRequestId") ? jsonNode.get("purchaseRequestId").asText() : "MISSING");
            logger.info("- dealId: {}", jsonNode.has("dealId") ? jsonNode.get("dealId").asText() : "MISSING");
            logger.info("- dealData present: {}", jsonNode.has("dealData"));

            if (jsonNode.has("dealData")) {
                com.fasterxml.jackson.databind.JsonNode dealDataNode = jsonNode.get("dealData");
                logger.info("DealData structure:");
                logger.info("- dealData type: {}", dealDataNode.getNodeType());

                java.util.List<String> fieldNames = new java.util.ArrayList<>();
                dealDataNode.fieldNames().forEachRemaining(fieldNames::add);
                logger.info("- dealData keys: {}", fieldNames);

                if (dealDataNode.has("customer")) {
                    logger.info("- customer present: {}", dealDataNode.get("customer") != null);
                    JsonNode customerNode = dealDataNode.get("customer");
                    if (customerNode != null) {
                        logger.info("  - customer.customerId: {}", customerNode.get("customerId"));
                        logger.info("  - customer.customerType: {}", customerNode.get("customerType"));
                    }
                } else {
                    logger.info("- customer field: MISSING");
                }

                if (dealDataNode.has("customerFinanceDetails")) {
                    logger.info("- customerFinanceDetails present: {}", dealDataNode.get("customerFinanceDetails") != null);
                } else {
                    logger.info("- customerFinanceDetails field: MISSING");
                }

                if (dealDataNode.has("retailerInfo")) {
                    logger.info("- retailerInfo present: {}", dealDataNode.get("retailerInfo") != null);
                } else {
                    logger.info("- retailerInfo field: MISSING");
                }

                if (dealDataNode.has("massOrders")) {
                    logger.info("- massOrders present: {}", dealDataNode.get("massOrders") != null);
                    logger.info("- massOrders type: {}", dealDataNode.get("massOrders").getNodeType());
                } else {
                    logger.info("- massOrders field: MISSING");
                }
            }

            return ResponseEntity.ok("Debug info logged. Check server logs.");

        } catch (Exception e) {
            logger.error("Error parsing JSON: {}", e.getMessage(), e);
            return ResponseEntity.badRequest().body("Error parsing JSON: " + e.getMessage());
        }
    }

    /**
     * Generate a new contract
     * Implements FR-01: Generate a New Contract via API
     * POST /contracts endpoint
     */
    @PostMapping
    @Operation(
        summary = "Generate a new contract",
        description = "Creates a new contract from purchase request data, generates PDF, and publishes event"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "201",
            description = "Contract created successfully",
            content = @Content(schema = @Schema(implementation = ContractResponse.class))
        ),
        @ApiResponse(
            responseCode = "400",
            description = "Invalid request data"
        ),
        @ApiResponse(
            responseCode = "409",
            description = "Contract already exists for this purchase request"
        ),
        @ApiResponse(
            responseCode = "500",
            description = "Internal server error"
        )
    })
    public ResponseEntity<ContractResponse> generateContract(
            @Valid @RequestBody ContractRequest request,
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            HttpServletRequest httpRequest) {

        // Log raw request details for debugging
        logger.info("Raw request details - Content-Type: {}, Content-Length: {}",
                   httpRequest.getContentType(), httpRequest.getContentLength());

        logger.info("Received contract generation request for purchaseRequestId: {}",
                   request.getPurchaseRequestId());

        // Log detailed request structure for debugging
        logger.info("Request structure - purchaseRequestId: {}, dealId: {}",
                   request.getPurchaseRequestId(), request.getDealId());

        if (request.getDealData() != null) {
            ContractRequest.DealData dealData = request.getDealData();
            logger.info("DealData received - dealId: {}", dealData.getDealId());
            logger.info("DealData field presence - customer: {}, customerFinanceDetails: {}, retailerInfo: {}, massOrders: {}",
                       dealData.getCustomer() != null,
                       dealData.getCustomerFinanceDetails() != null,
                       dealData.getRetailerInfo() != null,
                       dealData.getMassOrders() != null);

            // Log customer details if present
            if (dealData.getCustomer() != null) {
                Map<String, Object> customer = dealData.getCustomer();
                logger.info("Customer details - customerId: {}, customerType: {}",
                           customer.get("customerId"),
                           customer.get("customerType"));
            }

            if (dealData.getMassOrders() != null) {
                logger.info("MassOrders size: {}", dealData.getMassOrders().size());
            }
        } else {
            logger.warn("DealData is null in received request");
        }

        ContractResponse response = contractService.generateContract(request);

        // Create location header for the newly created resource
        URI location = URI.create("/v1/contracts/" + response.getContractId());

        logger.info("Contract generation completed successfully, contractId: {}", 
                   response.getContractId());

        return ResponseEntity.created(location).body(response);
    }

    /**
     * Retrieve contract details by ID
     * Implements FR-02: Retrieve Contract Details
     * GET /contracts/{contractId} endpoint
     */
    @GetMapping("/{contractId}")
    @Operation(
        summary = "Retrieve contract details",
        description = "Gets the complete contract object in JSON format by contract ID"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Contract details retrieved successfully",
            content = @Content(schema = @Schema(implementation = ContractDetailsResponse.class))
        ),
        @ApiResponse(
            responseCode = "404",
            description = "Contract not found"
        ),
        @ApiResponse(
            responseCode = "500",
            description = "Internal server error"
        )
    })
    public ResponseEntity<ContractDetailsResponse> getContractById(
            @Parameter(description = "Contract ID", required = true)
            @PathVariable String contractId,
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId) {

        logger.info("Received request to retrieve contract details for contractId: {}", contractId);

        ContractDetailsResponse response = contractService.getContractById(contractId);

        logger.info("Contract details retrieved successfully for contractId: {}", contractId);

        return ResponseEntity.ok(response);
    }

    /**
     * Download contract PDF
     * Implements FR-03: Retrieve Contract PDF
     * GET /contracts/{contractId}/pdf endpoint
     */
    @GetMapping("/{contractId}/pdf")
    @Operation(
        summary = "Download contract PDF",
        description = "Downloads the PDF file for a specific contract"
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "PDF file downloaded successfully",
            content = @Content(mediaType = "application/pdf")
        ),
        @ApiResponse(
            responseCode = "404",
            description = "Contract or PDF not found"
        ),
        @ApiResponse(
            responseCode = "500",
            description = "Internal server error"
        )
    })
    public ResponseEntity<Resource> downloadContractPdf(
            @Parameter(description = "Contract ID", required = true)
            @PathVariable String contractId,
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId) {

        logger.info("Received request to download PDF for contractId: {}", contractId);

        String pdfLocation = contractService.getContractPdfLocation(contractId);

        // Create file resource
        File pdfFile = new File(pdfLocation);
        if (!pdfFile.exists()) {
            logger.error("PDF file not found at location: {}", pdfLocation);
            return ResponseEntity.notFound().build();
        }

        Resource resource = new FileSystemResource(pdfFile);

        // Set appropriate headers
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDispositionFormData("attachment", contractId + ".pdf");
        
        // Add CORS headers for file downloads
        headers.add("Access-Control-Allow-Origin", "*");
        headers.add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        headers.add("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Trace-Id");
        headers.add("Access-Control-Expose-Headers", "Content-Disposition, Content-Type, Content-Length");

        logger.info("PDF download initiated for contractId: {}", contractId);

        return ResponseEntity.ok()
            .headers(headers)
            .body(resource);
    }
}
