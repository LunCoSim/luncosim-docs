---
title: Requirements and structure
chapter: 8
section: 1
---

# Requirements and structure

Keep the requirement in SysML. Keep the measurement procedure in Rhai and the
physical scene in USD. This split lets a requirement survive changes to the
scene or test implementation without duplicating its acceptance limit.

## Add SysML source to a Twin

SysML source remains ordinary text in the Twin. Declare its entry point and
search root in `twin.toml`:

```toml
[sysml]
root = "requirements/rover.sysml"
paths = ["requirements"]
```

`root` selects the entry-point file. `paths` limits source discovery and
defaults to `["."]` when omitted. Keep related `.sysml` and `.kerml` files
under a declared root so package references can resolve together. The full
field contract is in [twin.toml](../reference/twin-toml.md#modelica-and-sysml-roots).

## Connect the requirement to its subject

This example follows the standard textual notation. It defines a power
requirement, gives it a typed criterion, identifies the rover it applies to,
links that rover with `satisfy`, and names a verification case.

```sysml
package RoverRequirements {
    private import ScalarValues::String;
    private import SI::W;
    private import ISQ::PowerValue;

    attribute def SourceLocator :> String;
    enum def EvidenceSourceRole { Reference; }

    part def EvidenceSource {
        attribute role : EvidenceSourceRole;
        attribute locator : SourceLocator;
    }

    part def RequirementEvidence {
        ref targetRequirement : SysML::RequirementUsage;
        ref part sources : EvidenceSource[0..*];
    }

    part def Rover;
    part rover : Rover;

    requirement def PowerBudget {
        doc /* The rover shall deliver at least minimumPower under nominal conditions. */
        attribute minimumPower : PowerValue = 45.0[W];
        require MinimumOutputPower;
    }

    constraint def MinimumOutputPower {
        in deliveredPower : PowerValue;
        in minimumPower : PowerValue;
        deliveredPower >= minimumPower;
    }

    satisfy PowerBudget by rover;

    requirement powerBudget : PowerBudget {
        doc /* Verify the rover's nominal electrical output. */
        subject rover : Rover;
    }

    verification def VerifyPowerBudget {
        subject rover : Rover;
        objective {
            verify powerBudget;
        }
    }

    part powerBudgetSource : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator =
            "twin://my-rover/requirements/power-budget-source.md";
    }

    part powerBudgetEvidence : RequirementEvidence {
        ref targetRequirement = powerBudget;
        ref sources = (powerBudgetSource);
    }
}
```

The `require` statement attaches a formal acceptance criterion to the
definition. The usage applies that definition to a subject. `satisfy` records
which part meets the requirement; the subject declaration does not create that
relationship for you. The `verify` membership names the SysML verification
case, while the Twin manifest later binds that case to an executable scene
test.

The source-evidence usage links the requirement to a typed source record. Put
the referenced note at the stated Twin path, or change the locator to the
source you use. Keep the requirement statement normative. Record implementation
status, open decisions, and test results in their own evidence or status
records.

## Write criteria that can be checked

Give each requirement one subject and one observable outcome. State units,
operating conditions, tolerance, and time window when they affect the pass
decision. A `require` criterion can use a bounded subset of typed SysML
expressions; an authored Rhai observer supplies the observations needed to
evaluate it.

Use quantity and unit types for engineering values. Do not store a numeric limit
as a string or duplicate it in a Rhai check table. LunCoSim resolves supported
unit definitions and preserves source identity, but unsupported unit
expressions remain unavailable rather than being guessed.

Run `ValidateSysml` to review structural findings. It can flag requirements
without documentation, a subject, source evidence, a formal criterion, or a
resolved verification link. It also flags identifier-like strings that look
like enumerators or system-member names; model those as typed enums, parts, or
references instead.

## Keep the model layers separate

- Put logical parts, ports, connections, requirements, and trace links in
  SysML.
- Put scene prim paths, geometry, materials, and physical schemas in USD.
- Put continuous state and equations in Modelica.
- Put provider selection, runtime observations, and pass/fail policy in Rhai.

LunCoSim's Structure view can browse packages, parts, interfaces, ports, and
connections from the analyzed source. It is a source-navigation tool; it does
not edit a graphical SysML diagram.

## Related

- [Analysis and verification](analysis-and-verification.md): inspect, lint,
  and test the model.
- [Formats](../general/formats.md): choose the owner for each authored fact.
- [Twin manifest](../reference/twin-toml.md): SysML roots and verification
  registry fields.
- [OMG SysML v2 specification](https://www.omg.org/spec/SysML/2.0): normative
  language reference.
- [OMG KerML specification](https://www.omg.org/spec/KerML/1.0): the kernel
  language that defines SysML v2 semantics.
