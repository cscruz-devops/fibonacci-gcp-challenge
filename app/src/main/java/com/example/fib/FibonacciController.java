package com.example.fib;

import com.example.fib.model.ErrorResponse;
import com.example.fib.model.NextFibResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@RestController
public class FibonacciController {

  private static final int MIN = 1;
  private static final int MAX = 1000;

  private static final List<Integer> FIBS_IN_SCOPE = buildFibsInScope();
  private static final Set<Integer> FIBS_SET = new HashSet<>(FIBS_IN_SCOPE);

  private static List<Integer> buildFibsInScope() {
    List<Integer> list = new ArrayList<>();
    int a = 0, b = 1;
    while (b <= MAX) {
      if (b >= MIN) list.add(b);
      int c = a + b;
      a = b;
      b = c;
    }
    return list;
  }

  private final ObjectMapper mapper = new ObjectMapper();

  @PostMapping(value = "/", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<?> handle(@RequestBody(required = false) String body,
                                  @RequestHeader(value = "Content-Type", required = false) String contentType) {

    if (contentType == null || !contentType.toLowerCase().contains("application/json")) {
      return badRequest(new ErrorResponse("invalid request"));
    }
    if (body == null || body.isBlank()) {
      return badRequest(new ErrorResponse("invalid request"));
    }

    Integer n;
    try {
      JsonNode root = mapper.readTree(body);
      if (root == null || !root.has("fibonacci_number")) {
        return badRequest(new ErrorResponse("invalid request"));
      }
      JsonNode node = root.get("fibonacci_number");
      if (node == null || !node.isInt()) {
        String raw = (node == null) ? "null" : node.toString();
        return badRequest(new ErrorResponse(raw + " is not an integer"));
      }
      n = node.asInt();
    } catch (Exception e) {
      return badRequest(new ErrorResponse("invalid request"));
    }

    if (n < MIN || n > MAX) {
      int closest = closestFibInScope(n);
      return badRequest(new ErrorResponse(n + " is not a Fibonacci number. The closest Fibonacci number in scope is " + closest));
    }

    if (!FIBS_SET.contains(n)) {
      int closest = closestFibInScope(n);
      return badRequest(new ErrorResponse(n + " is not a Fibonacci number. The closest Fibonacci number in scope is " + closest));
    }

    long next = nextFib(n);
    return ResponseEntity.ok(new NextFibResponse(next));
  }

  private long nextFib(int n) {
    int a = 0, b = 1;
    while (b < n) {
      int c = a + b;
      a = b;
      b = c;
    }
    return (long) a + b;
  }

  private int closestFibInScope(int n) {
    int best = FIBS_IN_SCOPE.get(0);
    int bestDiff = Math.abs(n - best);
    for (int f : FIBS_IN_SCOPE) {
      int d = Math.abs(n - f);
      if (d < bestDiff) {
        bestDiff = d;
        best = f;
      }
    }
    return best;
  }

  private ResponseEntity<ErrorResponse> badRequest(ErrorResponse e) {
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).contentType(MediaType.APPLICATION_JSON).body(e);
  }
}
