package m0rjc.ax25.generator.model;

import m0rjc.ax25.generator.visitor.IModelVisitor;

/**
 * A precondition that can be applied to a Transition.
 * 
 * Preconditions are immutable, so instances can be reused.
 */
public abstract class Precondition
{
	/**
	 * The visitor will be visited as part of the preconditions phase of building the 
	 * transition.
	 * @param visitor
	 */
	public abstract void accept(IModelVisitor visitor);

	/**
	 * True if this value depends on this variable and only this variable and accepts the given
	 * input.
	 * @param variable variable in use
	 * @param value expected value
	 */
	public abstract boolean accepts(Variable variable, int value);

	/**
	 * Utility method to create a condition that checks a flag
	 * @return
	 */
	public static Precondition checkFlag(Variable holdingVariable, String flagName, boolean expectedValue)
	{
		return new FlagCheckPrecondition(holdingVariable, holdingVariable.getBit(flagName), expectedValue);
	}
}
