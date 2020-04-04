//51 percent simple consensus algorithm model.

const CONSENSUS = 51;

function calPer(incBy, from,  to) {
   for(let i = from; i< to; i++) {

    // Get the amount of vote needed.
    const requireVote =  i * (CONSENSUS/100);

    let addInc;
    if((i % 100) == 0) {
        addInc = requireVote;
    } else {
        addInc = requireVote + incBy;
    }
    // What percent is increased by adding 1 voter.
    const perInc = (100/requireVote) * addInc;

    console.log('Total community: ', i);
    console.log('Require vote: ', requireVote);
    console.log('Increase by one: ', addInc);
    console.log('Percentage increase: ', perInc);

    // Get the difference in percentage.
    const incDiff = perInc - 100;
    console.log('Increase Difference Per: ', incDiff);

    // Reduce the voter by 1.
    const reduceByOne = requireVote - 1;
    console.log('Total Community reduced by one: ', reduceByOne);  

    // Percentage after reduction.
    const reductionPer = (100/requireVote) * reduceByOne;
    console.log('reduction percentage', reductionPer);

    // Reduction percentaget difference.
    const decDiff = 100 - reductionPer;
    console.log('decrease percentage difference', decDiff);

    console.log('-------------------------------------');
   }
}

calPer(1, 1,500) ;