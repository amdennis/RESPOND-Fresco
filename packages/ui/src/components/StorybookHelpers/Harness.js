import PropTypes from 'prop-types';
import { merge } from '@codaco/utils';

function Harness({ children, requiredProps, ...props }) {
  const fullProps = merge({}, requiredProps, props);
  return children(fullProps);
}

Harness.propTypes = {
  requiredProps: PropTypes.object.isRequired,
};

export default Harness;
