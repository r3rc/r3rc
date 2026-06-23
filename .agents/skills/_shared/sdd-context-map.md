# Context Map

<!-- Relationships BETWEEN capabilities (not entities). Durable, prose-maintained, non-deltable.
     See the sdd-domain-format rule. Stays small (sparse edges between capabilities); a large map is a
     coupling smell to fix in design, not a file to split. -->

<!-- One bullet per relationship:

- **<A> → <B>** — <relationship-type>; <one-line rationale>
  - Interaction: <event> (<A>) → <effect> (<B>)

  relationship-type ∈ { customer-supplier | upstream/downstream | source-of-truth |
                        anti-corruption boundary | shared kernel }
  The behavioral effect itself is a #### Scenario: in the triggering capability's spec. -->
