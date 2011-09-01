package m0rjc.ax25.generator.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import m0rjc.ax25.generator.visitor.IModelVisitor;
import m0rjc.ax25.generator.visitor.INode;

/**
 * A node in a state model.
 * @author Richard Corfield
 */
public class Node implements INode
{
	/** Name for this state */
	private String m_stateName;
	
	/** Owning model */
	private StateModel m_model;
	
	/** Code to be run on entry to the state */
	private List<Command> m_entryCode = new ArrayList<Command>();
	
	/** 
	 * Transitions out of this state.
	 * If empty then this is an end-state and should "become" the
	 * initial state once any entry code has run.
	 */
	private List<Transition> m_transitions = new ArrayList<Transition>();
	
	/**
	 * Guard conditions on entry. 
	 * do not allow entry
	 */
	private List<Precondition> m_entryPreconditions = new ArrayList<Precondition>();
	
	/**
	 * Create a node with given name belonging to given model
	 * @param stateName
	 * @param stateModel
	 */
	public Node(String stateName, StateModel stateModel)
	{
		m_stateName = stateName;
		m_model = stateModel;
	}

	/**
	 * Return the owning state model.
	 */
	public StateModel getModel()
	{
		return m_model;
	}
	
	/**
	 * Encode the transitions needed to read the given string.
	 * This will create a chain of nodes and transitions (reusing any
	 * that already exist.)
	 * 
	 * @param string
	 * @return the node that is entered once the last character is read
	 * @exception should the state conflict with existing code.
	 */
	public Node addString(String string) throws Exception
	{
		char ch = string.charAt(0);
		Node node = getOrCreateTransition(ch).getNode();
		if(string.length() > 1)
		{
			return node.addString(string.substring(1));
		}
		return node;
	}

	/**
	 * Get or create a transition that covers a literal value
	 * @param ch
	 * @return
	 */
	private Transition getOrCreateTransition(int ch) throws Exception
	{
		Variable input = m_model.getInputVariable();
		
		for(Transition t : m_transitions)
		{
			if(t.accepts(input, ch))
			{
				return t;
			}
		}
		
		Transition t = new Transition(m_model.createNode())
			.whenEqual(input, ch);
		
		m_transitions.add(t);
		return t;
	}

	/**
	 * Create an empty transition to a new node
	 */
	private Transition createEmptyTransitionToNewNode()
	{
		return new Transition(m_model.createNode());
	}
	
	/**
	 * Create an empty transition to this node
	 */
	private Transition createSelfTransition()
	{
		return new Transition(this);
	}
	
	/**
	 * Add a condition to check before allowing entry to this node
	 */
	public Node addEntryCondition(Precondition p)
	{
		m_entryPreconditions.add(p);
		return this;
	}

	/**
	 * Create node or nodes to capture numbers.
	 * 
	 * If max > min then the result will be a null terminated string. Allow space for the null.
	 * If max == min then the result will not be null terminated.
	 * 
	 * @return the node that is entered on reading the last number
	 */
	public Node addNumbers(int min, int max, Variable storage) throws Exception
	{
		Variable input = m_model.getInputVariable();
		CompositePrecondition p = new CompositePrecondition(
				VariableValuePrecondition.createGE(input, '0'),
				VariableValuePrecondition.createLE(input, '9'));
		return addInputClassSequence(p, min, max, storage);
	}

	/** Add numbers but do not store the result */
	public Node addNumbers(int min, int max) throws Exception
	{
		return addNumbers(min,max,null);
	}
	
	/**
	 * Create node or nodes to capture based on the given condition
	 * 
	 * If max > min then the result will be a null terminated string. Allow space for the null.
	 * If max == min then the result will not be null terminated.
	 * 
	 * @return the node that is entered on reading the last input
	 */
	private Node addInputClassSequence(Precondition condition, int min, int max, Variable storage) throws Exception
	{
		Node exitNode;
		Variable counter = m_model.getCountVariable();
		Variable input = m_model.getInputVariable();
		boolean requiresNullTerminatedString = max > min;
		
		CompositeCommand storeCommand = new CompositeCommand();
		if(storage != null)
		{
			storeCommand.add(Command.storeValueIndex(input, storage, counter))
					    .add(Command.incrementValue(counter));
			if(requiresNullTerminatedString)
				storeCommand.add(Command.clearIndexedValue(storage, counter));
		}
		
		assert storage == null || storage.getSize() >= (requiresNullTerminatedString ? max+1 : max);
		
		// This node - clear the counter on entry
		addEntryCommand(Command.clearValue(counter));
		if(storage != null) addEntryCommand(Command.clearValue(storage));
		
		// The target state
		if(min == 0)
		{
			exitNode = this;
		}
		else if(min == 1)
		{
			// Any numbers allow us to exit
			exitNode = createEmptyTransitionToNewNode()
				.when(condition)
				.doCommand(storeCommand)
				.getNode();
		}
		else
		{
			// First number takes us into a state where we start collecting numbers until we reach the minimum
			Node numbersNode = createEmptyTransitionToNewNode()
							.when(condition)
							.when(VariableValuePrecondition.createLE(counter, min - 2))
							.getNode();

			// Subsequent numbers less than min keep us in this state
			if(min > 2)
			{
				numbersNode.createSelfTransition()
						   .when(condition)
						   .when(VariableValuePrecondition.createLE(counter, min - 2))
						   .doCommand(storeCommand);
			}
			
			// Once we hit min then we can go to the exit state
			exitNode = numbersNode.createEmptyTransitionToNewNode()
						   .when(condition)
						   .when(VariableValuePrecondition.createGE(counter, min - 1))
						   .doCommand(storeCommand)
						   .getNode();
		}

		if(max > min)
		{
			exitNode.createSelfTransition()
				.when(condition)
				.when(VariableValuePrecondition.createLE(counter, max - 1))
				.doCommand(storeCommand);
		}
		
		return exitNode;
	}
	
	/**
	 * Create a node or nodes to skip over numbers
	 * @return
	 * @throws Exception 
	 */
	public Node addNumbers(int i) throws Exception
	{
		return addNumbers(i,i,null);
	}


	/**
	 * Add transitions out of this node.
	 */
	public void addChoices(Transition... transitions)
	{
		for(Transition t : transitions)
		{
			m_transitions.add(t);
		}
	}

	/**
	 * Add commands to execute on entry to this node.
	 * @return this node
	 */
	public Node addEntryCommand(Command c)
	{
		m_entryCode.add(c);
		return this;
	}

	/**
	 * @see m0rjc.ax25.generator.visitor.INode#getStateName()
	 */
	@Override
	public String getStateName()
	{
		return m_stateName;
	}

	/**
	 * @see m0rjc.ax25.generator.visitor.INode#hasTransitions()
	 */
	@Override
	public boolean hasTransitions()
	{
		return !m_transitions.isEmpty();
	}
	
	/**
	 * Visit the node, then its transitions.
	 * Then visit child nodes.
	 * @param seenNodes 
	 * @param visitor
	 */
	public void accept(Set<String> seenNodes, IModelVisitor visitor)
	{
		if(seenNodes.add(getStateName()))
		{
			visitor.startNode(this);
			for(Transition t : m_transitions)
			{
				t.accept(visitor, m_model);
			}
			visitor.endNode(this);
			
			for(Transition t : m_transitions)
			{
				Node n = t.getNode(m_model);
				n.accept(seenNodes, visitor);
			}
		}
	}

	/** Return the preconditions for entry to this node */
	public List<Precondition> getEntryPreconditions()
	{
		return m_entryPreconditions;
	}

	/** Return the list of commands to perform on entry to this node. */
	public List<Command> getEntryCommands()
	{
		return m_entryCode;
	}
}
