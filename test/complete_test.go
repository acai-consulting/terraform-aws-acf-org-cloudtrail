package test

import 
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExampleComplete(t *testing.T) {
	// retryable errors in terraform testing.
	t.Log("Starting Sample Module test")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/complete",
		NoColor:      false,
		Lock:         true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	templateOutput := terraform.Output(t, terraformOptions, "template")

	t.Log(templateOutput)
	// Do testing. I.E check if your ressources are deployed via AWS GO SDK
}
